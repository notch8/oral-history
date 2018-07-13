class OralHistoryItem
  attr_accessor :attributes

  def initialize(attr={})
    @attributes = attr
  end

  def self.import(args)
    progress = args[:progress] || true
    limit = args[:limit] || 20000000  # essentially no limit
    url = args[:url] || "http://digital2.library.ucla.edu/dldataprovider/oai2_0.do"
    set = args[:set] || "oralhistory"
    client = OAI::Client.new url, :headers => { "From" => "rob@notch8.com" }, :parser => 'rexml', metadata_prefix: 'mods'
    response = client.list_records(set: set, metadata_prefix: 'mods')

    if progress
      bar = ProgressBar.new(response.doc.elements['//resumptionToken'].attributes['completeListSize'].to_i)
    end
    total = 0
    records = response.full.each do |record|
      history = OralHistoryItem.new
      if record.header
        if record.header.identifier
          history.attributes['id_t'] = record.header.identifier.split('/').last
          history.attributes['id'] = total # Digest::MD5.hexdigest(record.header.identifier).to_i(16)
        end
        if record.header.datestamp
          history.attributes[:timestamp] = Time.parse(record.header.datestamp)
        end
      end
      history.attributes["audio_b"] = false
      if record.metadata
        record.metadata.children.each do |set|
          next if set.class == REXML::Text
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
            elsif child.name == "abstract" ||
                  child.name == "extent"
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
              history.attributes["rights_t"] = child.text
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
                history.attributes["author_t"] ||= []
                history.attributes["author_t"] << child.elements['mods:namePart'].text
              elsif child.elements['mods:role/mods:roleTerm'].text == "interviewee"
                history.attributes["interviewee_display"] = child.elements['mods:namePart'].text
                history.attributes["interviewee_t"] ||= []
                history.attributes["interviewee_t"] << child.elements['mods:namePart'].text
                history.attributes["interviewee_sort"] = child.elements['mods:namePart'].text
              end
            elsif child.name == "relatedItem" && child.attributes['type'] == "constituent"
              history.attributes["children_t"] ||= []
              child_document = {
                'id': Digest::MD5.hexdigest(child.elements['mods:identifier'].text).to_i(16),
                "id_t": child.elements['mods:identifier'].text,
                "url_t": child.attributes['href'],
                "title_t": child.elements['mods:titleInfo/mods:title'].text,
                "order_i": child.elements['mods:part'].attributes['order'],
                "description_t": child.elements['mods:tableOfContents'].text,
                "time_log_t": child.elements['mods:location/mods:url[@usage="timed log"]'].text
              }
              if child.attributes['href'].present?
                history.attributes["audio_b"] = true
              end
              history.attributes["children_t"] << child_document.to_json
            elsif child.name == "relatedItem" && child.attributes['type'] == "series"
              history.attributes["series_facet"] = child.elements['mods:titleInfo/mods:title'].text
              history.attributes["series_t"] = child.elements['mods:titleInfo/mods:title'].text
              history.attributes["series_sort"] = child.elements['mods:titleInfo/mods:title'].text              
            elsif child.name == "note"
              if child.attributes['type'] == 'biographical'
                history.attributes["biographical_display"] = child.text
                history.attributes["biographical_t"] ||= []
                history.attributes["biographical_t"] << child.text
              end
              history.attributes["description_t"] ||= []
              history.attributes["description_t"] << child.text
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
            end
          end
        end
      end
      history.index_record
      if progress
        bar.increment!
      end
      total += 1
      break if total > limit
    end
  end

  def id
    self.attribtues[:id]
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
end
