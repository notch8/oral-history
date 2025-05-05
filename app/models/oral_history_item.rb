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
    return @index_logger if defined?(@index_logger)

    log_path = ENV['DEBUG_INDEXING'] ? "/dev/null" : Rails.root.join('log', 'importer.log')
    begin
      FileUtils.mkdir_p(File.dirname(log_path)) unless File.directory?(File.dirname(log_path))
      logger = ActiveSupport::Logger.new(log_path)
      logger.formatter = Logger::Formatter.new
      @index_logger = ActiveSupport::TaggedLogging.new(logger)
    rescue => e
      Rails.logger.error { "Failed to initialize OralHistoryItem.index_logger: #{e.message}" }
      @index_logger = Rails.logger
    end
  end

  def self.client(args)
    base_url = ENV['OAI_BASE_URL'] || 'https://oh-staff.library.ucla.edu'
    url = args[:url] || "#{base_url}/oai/"

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

  def self.import_single(id)
    converted_id = id.gsub('-','/')
    record = self.get(identifier: converted_id)&.record
    oh_item = process_record(record)
    oh_item.index_record

    # The ProcessPeakJob logic was previously here and has been removed until full fix is implemented
    return oh_item
  rescue => exception
    Rollbar.error('Error importing record', exception)
    OralHistoryItem.index_logger.error("🛑 #{exception.message}\n#{exception.backtrace}")
  end

  def self.process_record(record)
    if record.header.blank? || record.header.identifier.blank?
      return false
    end
    record_id = record.header.identifier.gsub('/','-')
    oh_item = OralHistoryItem.find_or_new(record_id) #Digest::MD5.hexdigest(record.header.identifier).to_i(16))
    oh_item.attributes['id_t'] = oh_item.id
    if record.header.datestamp
      oh_item.attributes[:timestamp] = Time.parse(record.header.datestamp)
    end

    oh_item.attributes["audio_b"] = false
    if record.metadata
      record.metadata.children.each do |set|
        next if set.class == REXML::Text
        has_xml_transcripts = false
        pdf_text = ''
        oh_item.attributes["children_t"] ||= []
        oh_item.attributes["transcripts_json_t"] ||= []
        oh_item.attributes["description_t"] ||= []
        oh_item.attributes['person_present_t'] ||= []
        oh_item.attributes['place_t'] ||= []
        oh_item.attributes['supporting_documents_t'] ||= []
        oh_item.attributes['interviewer_history_t'] ||= []
        oh_item.attributes['process_interview_t'] ||= []
        oh_item.attributes['links_t'] ||= []
        set.children.each do |child|
        next if child.class == REXML::Text

          if child.name == "titleInfo" # <mods:titleInfo>
            child.elements.each('mods:title') do |title|
              title_text = title.text.to_s.strip
              if(child.attributes["type"] == "alternative") && title_text.size > 0
                oh_item.attributes["subtitle_display"] ||= title_text
                oh_item.attributes["subtitle_t"] ||= []
                if !oh_item.attributes["subtitle_t"].include?(title_text)
                  oh_item.attributes["subtitle_t"] << title_text
                end
              elsif title_text.size > 0
                oh_item.attributes["title_display"] ||= title_text
                oh_item.attributes["title_t"] ||= []
                if !oh_item.attributes["title_t"].include?(title_text)
                  oh_item.attributes["title_t"] << title_text
                end
              end
            end

          # not in new oai feed remove?
          # elsif child.name == "typeOfResource"
          #   oh_item.attributes["type_of_resource_display"] = child.text
          #   oh_item.attributes["type_of_resource_t"] ||= []
          #   oh_item.attributes["type_of_resource_t"] << child.text
          #   oh_item.attributes["type_of_resource_facet"] ||= []
          #   oh_item.attributes["type_of_resource_facet"] << child.text

          # <mods:accessCondition>
          elsif child.name == "accessCondition"
            oh_item.attributes["rights_display"] = [child.text]
            oh_item.attributes["rights_t"] ||= []
            oh_item.attributes["rights_t"] << child.text

          # <mods:language>
          elsif child.name == 'language'
            child.elements.each('mods:languageTerm') do |e|
              oh_item.attributes["language_facet"] = LanguageList::LanguageInfo.find(e.text).try(:name)
              oh_item.attributes["language_sort"] = LanguageList::LanguageInfo.find(e.text).try(:name)
              oh_item.attributes["language_t"] = [LanguageList::LanguageInfo.find(e.text).try(:name)]
            end

          # <mods:subject>
          elsif child.name == "subject"
            child.elements.each('mods:topic') do |e|
              oh_item.attributes["subject_topic_facet"] ||= []
              oh_item.attributes["subject_t"] ||= []
              oh_item.attributes["subject_topic_facet"] << e.text
              oh_item.attributes["subject_t"] << e.text
            end
            oh_item.attributes["subject_topic_facet"].uniq!
            oh_item.attributes["subject_t"].uniq!

          # <mods:name>
          elsif child.name == "name"

            # <mods:role>
            #   <mods:roleTerm type="text">interviewer</mods:roleTerm>
            if child.elements['mods:role/mods:roleTerm'].text == "interviewer"
              oh_item.attributes["author_display"] = child.elements['mods:namePart'].text
              oh_item.attributes["author_t"] ||= []
              if !oh_item.attributes["author_t"].include?(child.elements['mods:namePart'].text)
                oh_item.attributes["author_t"] << child.elements['mods:namePart'].text
              end

            # <mods:role>
            #   <mods:roleTerm type="text">interviewee</mods:roleTerm>
            elsif child.elements['mods:role/mods:roleTerm'].text == "interviewee"
              oh_item.attributes["interviewee_display"] = child.elements['mods:namePart'].text
              oh_item.attributes["interviewee_t"] ||= []
              if !oh_item.attributes["interviewee_t"].include?(child.elements['mods:namePart'].text)
                oh_item.attributes["interviewee_t"] << child.elements['mods:namePart'].text
              end
              oh_item.attributes["interviewee_sort"] = child.elements['mods:namePart'].text
            end

          # <mods:relatedItem type="constituent">
          elsif child.name == "relatedItem" && child.attributes['type'] == "constituent"
            time_log_url = ''
            order = child.elements['mods:part'].present? ? child.elements['mods:part'].attributes['order'] : 1
            if child.elements['mods:location/mods:url[@usage="timed log"]'].present?
              time_log_url = child.elements['mods:location/mods:url[@usage="timed log"]'].text
              transcript = self.generate_xml_transcript(time_log_url)
              oh_item.attributes["transcripts_json_t"] << {
                "transcript_t": transcript,
                "order_i": order
              }.to_json
              oh_item.attributes["transcripts_t"] ||= [] if has_xml_transcripts == false
              has_xml_transcripts = true
              transcript_stripped = ActionController::Base.helpers.strip_tags(transcript)
              oh_item.attributes["transcripts_t"] << transcript_stripped
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
              oh_item.attributes["audio_b"] = true
              oh_item.attributes["audio_display"] = "Yes"
            end
            oh_item.attributes["peaks_t"] ||= []
            child_doc_json = child_document.to_json
            oh_item.attributes["children_t"] << child_doc_json unless oh_item.attributes["children_t"].include? child_doc_json

          # <mods:relatedItem type="series">
          elsif child.name == "relatedItem" && child.attributes['type'] == "series"
            oh_item.attributes["series_facet"] = child.elements['mods:titleInfo/mods:title'].text
            oh_item.attributes["series_t"] = child.elements['mods:titleInfo/mods:title'].text
            oh_item.attributes["series_sort"] = child.elements['mods:titleInfo/mods:title'].text
            oh_item.attributes["abstract_display"] = child.elements['mods:abstract']&.text
            oh_item.attributes["abstract_t"] ||= []
            oh_item.attributes["abstract_t"] << child.elements['mods:abstract']&.text

          # <mods:note>
          elsif child.name == "note"
            if child.attributes == {}
              oh_item.attributes["admin_note_display"] = child.text
              oh_item.attributes["admin_note_t"] ||= []
              oh_item.attributes["admin_note_t"] << child.text
            end

            # <mods:note type="biographical">
            if child.attributes['type'].to_s.match('biographical')
              oh_item.attributes["biographical_display"] = child.text
              oh_item.attributes["biographical_t"] ||= []
              oh_item.attributes["biographical_t"] << child.text
            end

            # <mods:note type="personpresent">
            if child.attributes['type'].to_s.match('personpresent')
              oh_item.attributes['person_present_display'] = child.text
              oh_item.attributes['person_present_t'] << child.text
            end

            # <mods:note type="place">
            if child.attributes['type'].to_s.match('place')
              oh_item.attributes['place_display'] = child.text
              oh_item.attributes['place_t'] << child.text
            end

            # <mods:note type="supportingdocuments">
            if child.attributes['type'].to_s.match('supportingdocuments')
              oh_item.attributes['supporting_documents_display'] = child.text
              oh_item.attributes['supporting_documents_t'] << child.text
            end

            # <mods:note type="interviewerhistory">
            if child.attributes['type'].to_s.match('interviewerhistory')
              oh_item.attributes['interviewer_history_display'] = child.text
              oh_item.attributes['interviewer_history_t'] << child.text
            end

            # <mods:note type="processinterview">
            if child.attributes['type'].to_s.match('processinterview')
              oh_item.attributes['process_interview_display'] = child.text
              oh_item.attributes['process_interview_t'] << child.text
            end
            oh_item.attributes["description_t"] << child.text

          # <mods:location>
          elsif child.name == 'location'
            child.elements.each do |f|
              oh_item.attributes['links_t'] << [f.text, f.attributes['displayLabel']].to_json
              order = child.elements['mods:part'].present? ? child.elements['mods:part'].attributes['order'] : 1

              # <mods:location displayLabel=
              if f.attributes['displayLabel'] &&
                has_xml_transcripts == false &&
                oh_item.attributes["transcripts_t"].blank? &&
                f.attributes['displayLabel'].match(/Transcript/) &&
                f.text.match(/pdf/i)
                oh_item.should_process_pdf_transcripts = true
                pdf_text = f.text
                oh_item.attributes["transcripts_json_t"] << {
                  "order_i": order
                }.to_json
              end
            end

          # <mods:physicalDescription>
          elsif child.name == 'physicalDescription'
            oh_item.attributes["extent_display"] = child.elements['mods:extent'].text
            oh_item.attributes['extent_t'] ||= []
            oh_item.attributes['extent_t'] << child.elements['mods:extent'].text

          # <mods:abstract>
          elsif child.name == 'abstract'
            oh_item.attributes['interview_abstract_display'] = child.text
            oh_item.attributes["interview_abstract_t"] ||= []
            oh_item.attributes["interview_abstract_t"] << child.text
          end
        end
        if !has_xml_transcripts && oh_item.should_process_pdf_transcripts
          IndexPdfTranscriptJob.perform_later(oh_item.id, pdf_text)
        end
      end
    end
    return oh_item
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
    begin
      tmpl = Nokogiri::XSLT(File.read('public/convert.xslt'))
      resp = Net::HTTP.get(URI(url))

      document = Nokogiri::XML(resp)

      tmpl.transform(document).to_xml
    rescue => exception
      OralHistoryItem.index_logger.error("🛑 #{exception.message}\n#{exception.backtrace}")
    end
  end

  def self.total_records(args = {})
    base_url = ENV['OAI_BASE_URL'] || 'https://oh-staff.library.ucla.edu'
    url = args[:url] || "#{base_url}/oai/"

    client = OAI::Client.new(url, http: Faraday.new { |c| c.options.timeout = 600 }) # increase timeout
    response = client.list_records(metadata_prefix: 'oai_dc')

    count = 0
    response.each do |_record|
      count += 1
      # Optionally log or simulate activity here
      OralHistoryItem.index_logger.debug("🟡 Counting record #{count}") if count % 500 == 0
    end

    count
  rescue => e
    OralHistoryItem.index_logger.error("🛑 Failed to count OAI records: #{e.class} - #{e.message}")
    0
  end

  def self.total_records_from_response(response)
    count = 0
    response.each { count += 1 }
    count
  end

  def self.full_import(response, args = {}, &block)
    return false if !args[:override]
    limit = args[:limit] || 20000000
    total = 0
    new_record_ids ||= []

    records = response.full.to_a

    records.each do |record|
      begin
        oh_item = process_record(record)
        OralHistoryItem.index_logger.info("🟢 #{oh_item.id} imported — #{oh_item.attributes['title_display']}")
        oh_item.index_record
        new_record_ids << oh_item.id if oh_item.id
      rescue => exception
        Rollbar.error('Error processing record', exception)
        index_logger.error("#{exception.message}\n#{exception.backtrace}")
      end

      total += 1
      is_last = total >= limit || record == records.last

      yield(total, is_last) if block_given?
      break if total >= limit
    end

    SolrService.commit
    remove_deleted_records(new_record_ids) if args[:delete]
    total
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
end