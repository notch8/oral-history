require 'nokogiri'
require 'net/http'

class OralHistoryItem
  attr_accessor :attributes, :new_record, :should_process_pdf_transcripts

  def initialize(attr={})
    if attr.is_a?(Hash)
      @attributes = attr.with_indifferent_access
    else
      @attributes = attr
    end
  end

  def self.client(args)
    url = args[:url] || "http://digital2.library.ucla.edu/dldataprovider/oai2_0.do"
    OAI::Client.new url, :headers => { "From" => "rob@notch8.com" }, :parser => 'rexml', metadata_prefix: 'mods'
  end

  def self.fetch(args)
    set = args[:set] || "oralhistory"
    response = client(args).list_records(set: set, metadata_prefix: 'mods')
  end

  def self.get(args)
    response = client(args).get_record(identifier: args[:identifier], metadata_prefix: 'mods', )
  end


  def self.fetch_first_id
    response = self.fetch({progress: false, limit:1})
    response.full&.first&.header&.identifier&.split('/')&.last
  end

  def self.import(args)
    return false if !args[:override] && check_for_tmp_file
    begin
      create_import_tmp_file
      progress = args[:progress] || true
      limit = args[:limit] || 20000000  # essentially no limit
      response = self.fetch(args)
      if progress
        bar = ProgressBar.new(response.doc.elements['//resumptionToken'].attributes['completeListSize'].to_i)
      end
      total = 0
      new_record_ids = []

      response.full.each do |record|
        begin
          history = process_record(record)
          history.index_record
          if ENV['MAKE_WAVES'] && history.attributes["audio_b"] && history.new_record?
            ProcessPeakJob.perform_later(history.id)
          end
          new_record_ids << history.id
        rescue => exception
          Raven.capture_exception(exception)
        end
        if true
          yield(total) if block_given?        
        end
        
        if progress
          bar.increment!
        end
        total += 1
        break if total >= limit
      end
      #verify there is no limit argument which would allow deletion of all records after the limit
      if args[:limit] == 20000000
        remove_deleted_records(new_record_ids)
      end
      return total
    rescue => exception
      Raven.capture_exception(exception)
    ensure
      remove_import_tmp_file
    end
  end

  def self.import_single(id)
    record = self.get(identifier: id)&.record
    history = process_record(record)
    history.index_record
    return history
  end

  def self.process_record(record)
    if record.header.blank? || record.header.identifier.blank?
      return false
    end
    
    history = OralHistoryItem.find_or_new(record.header.identifier.split('/').last) #Digest::MD5.hexdigest(record.header.identifier).to_i(16))
    history.attributes['id_t'] = record.header.identifier.split('/').last
    if record.header.datestamp
      history.attributes[:timestamp] = Time.parse(record.header.datestamp)
    end

    history.attributes["audio_b"] = false
    if record.metadata
      record.metadata.children.each do |set|
        next if set.class == REXML::Text
        has_xml_transcripts = false
        pdf_text = ''
        history.attributes["author_t"] = []
        history.attributes["interviewee_t"] = []
        history.attributes["children_t"] = []
        history.attributes["transcripts_t"] = []
        history.attributes["transcripts_json_t"] = []
        history.attributes["description_t"] = []
        history.attributes['person_present_t'] = []
        history.attributes['place_t'] = []
        history.attributes['supporting_documents_t'] = []
        history.attributes['interviewer_history_t'] = []
        history.attributes['process_interview_t'] = []
        history.attributes['links_t'] = []
        set.children.each do |child|
        next if child.class == REXML::Text
          if child.name == "titleInfo"
            child.elements.each('mods:title') do |title|
              title_text = title.text.to_s.strip
              if(child.attributes["type"] == "alternative") && title_text.size > 0
                history.attributes["subtitle_display"] ||= title_text
                history.attributes["subtitle_t"] ||= []
                history.attributes["subtitle_t"] << title_text
              elsif title_text.size > 0
                history.attributes["title_display"] ||= title_text
                history.attributes["title_t"] ||= []
                history.attributes["title_t"] << title_text
              end
            end
          elsif child.name == "abstract"
            history.attributes[child.name + "_display"] = child.text
            history.attributes[child.name + "_t"] ||= []
            history.attributes[child.name + "_t"] << child.text
          elsif child.name == "typeOfResource"
            history.attributes["type_of_resource_display"] = child.text
            history.attributes["type_of_resource_t"] ||= []
            history.attributes["type_of_resource_t"] << child.text
            history.attributes["type_of_resource_facet"] ||= []
            history.attributes["type_of_resource_facet"] << child.text
          elsif child.name == "accessCondition"
            history.attributes["rights_display"] = [child.text]
            history.attributes["rights_t"] = []
            history.attributes["rights_t"] << child.text
          elsif child.name == 'language'
            child.elements.each('mods:languageTerm') do |e|
              history.attributes["language_facet"] = LanguageList::LanguageInfo.find(e.text).try(:name)
              history.attributes["language_sort"] = LanguageList::LanguageInfo.find(e.text).try(:name)
              history.attributes["language_t"] = [LanguageList::LanguageInfo.find(e.text).try(:name)]
            end
          elsif child.name == "subject"
            child.elements.each('mods:topic') do |e|
              history.attributes["subject_topic_facet"] ||= []
              history.attributes["subject_topic_facet"] << e.text
              history.attributes["subject_t"] ||= []
              history.attributes["subject_t"] << e.text
            end
          elsif child.name == "name"
            if child.elements['mods:role/mods:roleTerm'].text == "interviewer"
              history.attributes["author_display"] = child.elements['mods:namePart'].text
              history.attributes["author_t"] << child.elements['mods:namePart'].text
            elsif child.elements['mods:role/mods:roleTerm'].text == "interviewee"
              history.attributes["interviewee_display"] = child.elements['mods:namePart'].text
              history.attributes["interviewee_t"] << child.elements['mods:namePart'].text
              history.attributes["interviewee_sort"] = child.elements['mods:namePart'].text
            end
          elsif child.name == "relatedItem" && child.attributes['type'] == "constituent"
            time_log_url = ''
            order = child.elements['mods:part'].attributes['order']

            if child.elements['mods:location/mods:url[@usage="timed log"]'].present?
              time_log_url = child.elements['mods:location/mods:url[@usage="timed log"]'].text
              transcript = self.generate_transcript(time_log_url)
              history.attributes["transcripts_json_t"] << {
                "transcript_t": transcript,
                "order_i": order
              }.to_json
              history.attributes["transcripts_t"] = [] if has_xml_transcripts == false
              has_xml_transcripts = true
              transcript_stripped = ActionController::Base.helpers.strip_tags(transcript)
              history.attributes["transcripts_t"] << transcript_stripped
            end

            child_document = {
              'id': Digest::MD5.hexdigest(child.elements['mods:identifier'].text).to_i(16),
              "id_t": child.elements['mods:identifier'].text,
              "url_t": child.attributes['href'],
              "title_t": child.elements['mods:titleInfo/mods:title'].text,
              "order_i": order,
              "description_t": child.elements['mods:tableOfContents'].text,
              "time_log_t": time_log_url
            }

            if child.attributes['href'].present?
              history.attributes["audio_b"] = true
              history.attributes["audio_display"] = "Yes"
            end
            history.attributes["children_t"] << child_document.to_json
          elsif child.name == "relatedItem" && child.attributes['type'] == "series"
            history.attributes["series_facet"] = child.elements['mods:titleInfo/mods:title'].text
            history.attributes["series_t"] = child.elements['mods:titleInfo/mods:title'].text
            history.attributes["series_sort"] = child.elements['mods:titleInfo/mods:title'].text
            history.attributes["abstract_display"] = child.elements['mods:abstract'].text
            history.attributes["abstract_t"] = []
            history.attributes["abstract_t"] << child.elements['mods:abstract'].text
          elsif child.name == "note"
            if child.attributes['type'].to_s.match('biographical')
              history.attributes["biographical_display"] = child.text
              history.attributes["biographical_t"] = []
              history.attributes["biographical_t"] << child.text
            end
            if child.attributes['type'].to_s.match('personpresent')
              history.attributes['person_present_display'] = child.text
              history.attributes['person_present_t'] << child.text
            end
            if child.attributes['type'].to_s.match('place')
              history.attributes['place_display'] = child.text
              history.attributes['place_t'] << child.text
            end
            if child.attributes['type'].to_s.match('supportingdocuments')
              history.attributes['supporting_documents_display'] = child.text
              history.attributes['supporting_documents_t'] << child.text
            end
            if child.attributes['type'].to_s.match('interviewerhistory')
              history.attributes['interviewer_history_display'] = child.text
              history.attributes['interviewer_history_t'] << child.text
            end
            if child.attributes['type'].to_s.match('processinterview')
              history.attributes['process_interview_display'] = child.text
              history.attributes['process_interview_t'] << child.text
            end
            history.attributes["description_t"] << child.text
          elsif child.name == 'location'
            child.elements.each do |f|
              history.attributes['links_t'] << [f.text, f.attributes['displayLabel']].to_json
              if f.attributes['displayLabel'] && 
                has_xml_transcripts == false && 
                history.attributes["transcripts_t"].blank? && 
                f.attributes['displayLabel'].match(/Transcript/) && 
                f.text.match(/pdf/i)
                history.should_process_pdf_transcripts = true
                pdf_text = f.text
              end
            end
          elsif child.name == 'physicalDescription'
            history.attributes["extent_display"] = child.elements['mods:extent'].text
            history.attributes['extent_t'] = []
            history.attributes['extent_t'] << child.elements['mods:extent'].text
            
          end
        end
        if !has_xml_transcripts && history.should_process_pdf_transcripts
          IndexPdfTranscriptJob.perform_later(history.id, pdf_text)
        end
      end
    end
    return history
  end

  def new_record?
    self.attributes.is_a?(Hash)
  end

  def id
    self.attributes[:id]
  end

  def id=(value)
    self.attributes[:id] = value
  end

  def should_process_pdf_transcripts
    @should_process_pdf_transcripts ||= false
    @should_process_pdf_transcripts && !Delayed::Job.where("handler LIKE ? ", "%job_class: IndexPdfTranscriptJob%#{self.id}%").first
  end

  def to_solr
    attributes
  end

  def index_record
    SolrService.add(self.to_solr)
    #TODO allow for search capturing
    SolrService.commit
  end

  def remove_from_index
    SolrService.delete_by_id(self.id)
    SolrService.commit
  end

  def self.remove_deleted_records(new_record_ids)
    current_records = all_ids 
    new_record_ids.each do |id|
      current_records.delete(id)
    end
    if current_records.present?
      current_records.each do |id|
        SolrService.delete_by_id(id)
        SolrService.commit 
      end
    end
  end

  def self.all_ids
    return @all_ids if @all_ids.present?
    @all_ids ||= []
    SolrService.all_records do |record|
      @all_ids << record["id"]
    end
    @all_ids
  end

  def generate_peaks
    @peaks = Peaks::Processor.new()

    @peaks.from_solr_document self
  end

  def self.find(id)
    OralHistoryItem.new(SolrDocument.find(id))
  end

  def self.find_or_new(id)
    self.find(id)
  rescue Blacklight::Exceptions::RecordNotFound
    OralHistoryItem.new(id: id)
  end

  def self.generate_transcript(url)
    tmpl = Nokogiri::XSLT(File.read('public/convert.xslt'))
    resp = Net::HTTP.get(URI(url))

    document = Nokogiri::XML(resp)

    tmpl.transform(document).to_xml
  end

  def self.total_records(args = {})
    url = args[:url] || "http://digital2.library.ucla.edu/dldataprovider/oai2_0.do"
    set = args[:set] || "oralhistory"
    client = OAI::Client.new url, :headers => { "From" => "rob@notch8.com" }, :parser => 'rexml', metadata_prefix: 'mods'
    response = client.list_records(set: set, metadata_prefix: 'mods')
    response.doc.elements['//resumptionToken'].attributes['completeListSize'].to_i
  end

  def self.create_import_tmp_file
    FileUtils.touch(Rails.root.join('tmp/importer.tmp'))
  end

  def self.remove_import_tmp_file
    FileUtils.rm(Rails.root.join('tmp/importer.tmp'))
  end

  def self.check_for_tmp_file
    File.exist?(File.join('tmp/importer.tmp'))
  end
end


#           elsif child.name == "date"
#              if child.content.length == 4
#                pub_date = child.content.to_i
#              else
#                pub_date = Time.parse(child.content).year rescue nil
#              end
#              history.attributes["pub_date"] = pub_date
#              history.attributes["pub_date_sort"] = pub_date
            #elsif child.name == "coverage" # TODO
            #  child_name = child.name + "_t"
            #  history.attributes[child_name] ||= []
            #  history.attributes[child_name] << child.content####
#          elsif child.name == "format"
#              history.attributes["format"] = child.content
#              history.attributes[child.name + "_display"] = child.content
#              history.attributes[child.name + "_t"] ||= []
#              history.attributes[child.name + "_t"] << child.content
#            elsif child.name == "description"
#              history.attributes[child.name + "_display"] = child.content
#              history.attributes[child.name + "_t"] ||= []
#              history.attributes[child.name + "_t"] << child.content
#              if child.content.match(/BIOGRAPHICAL/)
#                history.attributes["description_facet"] = [child.content.to_s.truncate(10)]
#              end
#            else
#              history.attributes[child.name + "_display"] = child.content
#              history.attributes[child.name + "_t"] ||= []
#              history.attributes[child.name + "_t"] << child.content
