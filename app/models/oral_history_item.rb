require 'nokogiri'
require 'net/http'

class OralHistoryItem
  attr_accessor :attributes, :new_record, :should_process_pdf_transcripts

  def initialize(attr={})
    if attr.is_a?(Hash)
      @attributes = attr.with_indifferent_access
    else
      @attributes = attr.to_h.with_indifferent_access
    end
  end

  def self.index_logger
    log_path = if !ENV['DEBUG_INDEXING']
                 Rails.root.join('log', "indexing.log")
               else
                 "/dev/null"
               end

    logger           = ActiveSupport::Logger.new(log_path)
    logger.formatter = Logger::Formatter.new
    @@index_logger ||= ActiveSupport::TaggedLogging.new(logger)
  end


  def self.client(args)
    # Fetch the base URL from the environment variable, defaulting to a specific domain with protocol if not set.
    base_url = ENV['OAI_BASE_URL'] || 'https://oh-staff.library.ucla.edu'

    # Construct the full URL with a fallback path if none is provided in args.
    url = args[:url] || "#{base_url}/oai/"

    # Create a new OAI client with the constructed URL and Faraday configuration.
    OAI::Client.new(url, http: Faraday.new { |c| c.options.timeout = 300 })
  end

  def self.fetch(args)
    response = client(args).list_records
  end

  def self.get(args)
    if args.is_a?(Hash) && args.key?(:identifier)
      response = client(args).get_record(identifier: args[:identifier] )
    else
      response = client(args).fetch(identifier: identifier)
    end
  end

  def self.get_record(identifier)
    oai_client = self.client

    response = oai_client.get_record(identifier: identifier)
  end


  def self.fetch_first_id
    response = self.fetch({limit:1})
    response.full&.first&.header&.identifier
  end

  def self.import(args)
    return false if !args[:override] && check_for_tmp_file
    begin
      create_import_tmp_file
      limit = args[:limit] || 20000000  # essentially no limit
      response = self.fetch(args)
      total = 0
      new_record_ids = []

      response.full.each do |record|
        begin
          history = process_record(record)
          history.index_record
          if history.id
            new_record_ids << history.id
          else
            OralHistoryItem.index_logger.info("ID is nil for #{history.inspect}")
          end
          if ENV['MAKE_WAVES'] && history.attributes["audio_b"] && history.should_process_peaks?
            ProcessPeakJob.perform_later(history.id)
          end
        rescue => exception
          Rollbar.error('Error processing record', exception)
          OralHistoryItem.index_logger.error("#{exception.message}\n#{exception.backtrace}")
        end
        if true
          yield(total) if block_given?
        end

        total += 1
        break if total >= limit
      end
      # Hard commit now that we are done adding items, before we remove anything
      SolrService.commit
      #verify there is no limit argument which would allow deletion of all records after the limit
      if args[:delete]
        remove_deleted_records(new_record_ids)
      end
      return total
    rescue => exception
      Rollbar.error('Error importing record', exception)
      OralHistoryItem.index_logger.error("#{exception.message}\n#{exception.backtrace}")
    ensure
      remove_import_tmp_file
    end
  end

  def self.import_single(id)
    converted_id = id.gsub('-','/')
    record = self.get(identifier: converted_id)&.record
    history = process_record(record)
    history.index_record
    if ENV['MAKE_WAVES'] && history.attributes["audio_b"] && history.should_process_peaks?
      ProcessPeakJob.perform_later(history.id)
    end
    return history
  rescue => exception
    Rollbar.error('Error importing record', exception)
    OralHistoryItem.index_logger.error("#{exception.message}\n#{exception.backtrace}")
  end

  def self.process_record(record)
    if record.header.blank? || record.header.identifier.blank?
      return false
    end
    record_id = record.header.identifier.gsub('/','-')
    history = OralHistoryItem.find_or_new(record_id) #Digest::MD5.hexdigest(record.header.identifier).to_i(16))
    history.attributes['id_t'] = history.id
    if record.header.datestamp
      history.attributes[:timestamp] = Time.parse(record.header.datestamp)
    end

    history.attributes["audio_b"] = false
    if record.metadata
      record.metadata.children.each do |set|
        next if set.class == REXML::Text
        has_xml_transcripts = false
        pdf_text = ''
        history.attributes["children_t"] = []
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

          if child.name == "titleInfo" # <mods:titleInfo>
            child.elements.each('mods:title') do |title|
              title_text = title.text.to_s.strip
              if(child.attributes["type"] == "alternative") && title_text.size > 0
                history.attributes["subtitle_display"] ||= title_text
                history.attributes["subtitle_t"] ||= []
                if !history.attributes["subtitle_t"].include?(title_text)
                  history.attributes["subtitle_t"] << title_text
                end
              elsif title_text.size > 0
                history.attributes["title_display"] ||= title_text
                history.attributes["title_t"] ||= []
                if !history.attributes["title_t"].include?(title_text)
                  history.attributes["title_t"] << title_text
                end
              end
            end

          # not in new oai feed remove?
          # elsif child.name == "typeOfResource"
          #   history.attributes["type_of_resource_display"] = child.text
          #   history.attributes["type_of_resource_t"] ||= []
          #   history.attributes["type_of_resource_t"] << child.text
          #   history.attributes["type_of_resource_facet"] ||= []
          #   history.attributes["type_of_resource_facet"] << child.text

          # <mods:accessCondition>
          elsif child.name == "accessCondition"
            history.attributes["rights_display"] = [child.text]
            history.attributes["rights_t"] = []
            history.attributes["rights_t"] << child.text

          # <mods:language>
          elsif child.name == 'language'
            child.elements.each('mods:languageTerm') do |e|
              history.attributes["language_facet"] = LanguageList::LanguageInfo.find(e.text).try(:name)
              history.attributes["language_sort"] = LanguageList::LanguageInfo.find(e.text).try(:name)
              history.attributes["language_t"] = [LanguageList::LanguageInfo.find(e.text).try(:name)]
            end

          # <mods:subject>
          elsif child.name == "subject"
            child.elements.each('mods:topic') do |e|
              history.attributes["subject_topic_facet"] ||= []
              history.attributes["subject_topic_facet"] << e.text
              history.attributes["subject_t"] ||= []
              history.attributes["subject_t"] << e.text
            end

          # <mods:name>
          elsif child.name == "name"

            # <mods:role>
            #   <mods:roleTerm type="text">interviewer</mods:roleTerm>
            if child.elements['mods:role/mods:roleTerm'].text == "interviewer"
              history.attributes["author_display"] = child.elements['mods:namePart'].text
              history.attributes["author_t"] ||= []
              if !history.attributes["author_t"].include?(child.elements['mods:namePart'].text)
                history.attributes["author_t"] << child.elements['mods:namePart'].text
              end

            # <mods:role>
            #   <mods:roleTerm type="text">interviewee</mods:roleTerm>
            elsif child.elements['mods:role/mods:roleTerm'].text == "interviewee"
              history.attributes["interviewee_display"] = child.elements['mods:namePart'].text
              history.attributes["interviewee_t"] ||= []
              if !history.attributes["interviewee_t"].include?(child.elements['mods:namePart'].text)
                history.attributes["interviewee_t"] << child.elements['mods:namePart'].text
              end
              history.attributes["interviewee_sort"] = child.elements['mods:namePart'].text
            end

          # <mods:relatedItem type="constituent">
          elsif child.name == "relatedItem" && child.attributes['type'] == "constituent"
            time_log_url = ''
            order = child.elements['mods:part'].present? ? child.elements['mods:part'].attributes['order'] : 1
            if child.elements['mods:location/mods:url[@usage="timed log"]'].present?
              time_log_url = child.elements['mods:location/mods:url[@usage="timed log"]'].text
              transcript = self.generate_xml_transcript(time_log_url)
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
              "description_t": child.elements['mods:tableOfContents'].present? ? child.elements['mods:tableOfContents'].text : "Content",
              "time_log_t": time_log_url
            }

            if child.attributes['href'].present?
              history.attributes["audio_b"] = true
              history.attributes["audio_display"] = "Yes"
            end
            history.attributes["peaks_t"] ||= []
            child_doc_json = child_document.to_json
            history.attributes["peaks_t"] << child_doc_json unless history.attributes["peaks_t"].include? child_doc_json
            history.attributes["children_t"] << child_doc_json

          # <mods:relatedItem type="series">
          elsif child.name == "relatedItem" && child.attributes['type'] == "series"
            history.attributes["series_facet"] = child.elements['mods:titleInfo/mods:title'].text
            history.attributes["series_t"] = child.elements['mods:titleInfo/mods:title'].text
            history.attributes["series_sort"] = child.elements['mods:titleInfo/mods:title'].text
            history.attributes["abstract_display"] = child.elements['mods:abstract']&.text
            history.attributes["abstract_t"] = []
            history.attributes["abstract_t"] << child.elements['mods:abstract']&.text

          # <mods:note>
          elsif child.name == "note"
            if child.attributes == {}
              history.attributes["admin_note_display"] = child.text
              history.attributes["admin_note_t"] = []
              history.attributes["admin_note_t"] << child.text
            end

            # <mods:note type="biographical">
            if child.attributes['type'].to_s.match('biographical')
              history.attributes["biographical_display"] = child.text
              history.attributes["biographical_t"] = []
              history.attributes["biographical_t"] << child.text
            end

            # <mods:note type="personpresent">
            if child.attributes['type'].to_s.match('personpresent')
              history.attributes['person_present_display'] = child.text
              history.attributes['person_present_t'] << child.text
            end

            # <mods:note type="place">
            if child.attributes['type'].to_s.match('place')
              history.attributes['place_display'] = child.text
              history.attributes['place_t'] << child.text
            end

            # <mods:note type="supportingdocuments">
            if child.attributes['type'].to_s.match('supportingdocuments')
              history.attributes['supporting_documents_display'] = child.text
              history.attributes['supporting_documents_t'] << child.text
            end

            # <mods:note type="interviewerhistory">
            if child.attributes['type'].to_s.match('interviewerhistory')
              history.attributes['interviewer_history_display'] = child.text
              history.attributes['interviewer_history_t'] << child.text
            end

            # <mods:note type="processinterview">
            if child.attributes['type'].to_s.match('processinterview')
              history.attributes['process_interview_display'] = child.text
              history.attributes['process_interview_t'] << child.text
            end
            history.attributes["description_t"] << child.text

          # <mods:location>
          elsif child.name == 'location'
            child.elements.each do |f|
              history.attributes['links_t'] << [f.text, f.attributes['displayLabel']].to_json
              order = child.elements['mods:part'].present? ? child.elements['mods:part'].attributes['order'] : 1

              # <mods:location displayLabel=
              if f.attributes['displayLabel'] &&
                has_xml_transcripts == false &&
                history.attributes["transcripts_t"].blank? &&
                f.attributes['displayLabel'].match(/Transcript/) &&
                f.text.match(/pdf/i)
                history.should_process_pdf_transcripts = true
                pdf_text = f.text
                history.attributes["transcripts_json_t"] << {
                  "order_i": order
                }.to_json
              end
            end

          # <mods:physicalDescription>
          elsif child.name == 'physicalDescription'
            history.attributes["extent_display"] = child.elements['mods:extent'].text
            history.attributes['extent_t'] = []
            history.attributes['extent_t'] << child.elements['mods:extent'].text

          # <mods:abstract>
          elsif child.name == 'abstract'
            history.attributes['interview_abstract_display'] = child.text
            history.attributes["interview_abstract_t"] = []
            history.attributes["interview_abstract_t"] << child.text
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
    attributes.except("hashed_id_ssi")
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
    File.write(Rails.root.join('log', 'in_solr.json'), all_ids.to_json)
    File.write(Rails.root.join('log', 'new_ids.json'), new_record_ids.to_json)
    new_record_ids.each do |id|
      current_records.delete(id)
    end
    File.write(Rails.root.join('log', 'to_delete.json'), current_records.to_json)
    if current_records.present?
      current_records.each do |id|
        SolrService.delete_by_id(id)
        SolrService.commit
      end
    end
  end

  def self.all_ids
    @all_ids ||= SolrService.all_ids
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

  def self.generate_xml_transcript(url)
    tmpl = Nokogiri::XSLT(File.read('public/convert.xslt'))
    resp = Net::HTTP.get(URI(url))

    document = Nokogiri::XML(resp)

    tmpl.transform(document).to_xml
  end

  def self.total_records(args = {})
    # Fetch the base URL from the environment variable, defaulting to a specific domain with protocol if not set.
    base_url = ENV['OAI_BASE_URL'] || 'https://oh-staff.library.ucla.edu'

    # Construct the full URL with a fallback path if none is provided in args.
    url = args[:url] || "#{base_url}/oai/"

    # Create a new OAI client with the constructed URL and Faraday configuration.
    OAI::Client.new(url, http: Faraday.new { |c| c.options.timeout = 300 })
  end


  def has_peaks?
    self.attributes["peaks_t"].each_with_index do |peak, i|
      return false unless JSON.parse(peak)['peaks'].present?
    end

    true
  end

  def peak_job_queued?
    Delayed::Job.where("handler LIKE ? AND last_error IS ?", "%job_class: ProcessPeakJob%#{self.id}%", nil).present?
  end

  def pdf_transcript_job_queued?
    Delayed::Job.where("handler LIKE ? AND last_error IS ?", "%job_class: IndexPdfTranscriptJob%#{self.id}%", nil).present?
  end

  def should_process_peaks?
    !has_peaks? && !peak_job_queued?
  end

  def should_process_pdf_transcripts
    @should_process_pdf_transcripts ||= false
    @should_process_pdf_transcripts && !pdf_transcript_job_queued?
  end

  def self.create_import_tmp_file
    FileUtils.touch(Rails.root.join('tmp/importer.tmp'))
  end

  def self.remove_import_tmp_file
    tmp_file = Rails.root.join('tmp/importer.tmp')
    FileUtils.rm(tmp_file) if File.exist?(tmp_file)
  end

  def self.check_for_tmp_file
    File.exist?(File.join('tmp/importer.tmp'))
  end
end