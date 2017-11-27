class OralHistoryItem
  attr_accessor :attributes

  def initialize(attr={})
    @attributes = attr
  end

  def self.import(args)
    progress = args[:progress] || true
    limit = args[:limit] || 20000000  # essentially no limit
    url = args[:url] || "http://digital2.library.ucla.edu/oai2_0.do"
    set = args[:set] || "oralhistory"
    client = OAI::Client.new url, :headers => { "From" => "rob@notch8.com" }, :parser => 'libxml', metadata_prefix: 'oai_dc'
    response = client.list_records(set: set)

    if progress
      bar = ProgressBar.new(response.doc.find(".//resumptionToken").to_a.first.attributes["completeListSize"].to_i)
    end
    total = 0
    records = response.full.each do |record|
      history = OralHistoryItem.new
      if record.header
       if record.header.identifier
          history.attributes[:id] = record.header.identifier.split('/').last
        end
        if record.header.datestamp
          history.attributes[:timestamp] = Time.parse(record.header.datestamp)
        end
      end

      if record.metadata
        record.metadata.children.each do |set|
          set.children.each do |child|
            next if child.name == "text"
            if child.name == "title"
              if child.content.match(/alternative title/)
                history.attributes["subtitle_display"] ||= child.content
                history.attributes["subtitle_t"] ||= []
                history.attributes["subtitle_t"] << child.content
              else
                history.attributes["title_display"] ||= child.content
                history.attributes["title_t"] ||= []
                history.attributes["title_t"] << child.content
              end
           elsif child.name == "date"
              if child.content.length == 4
                pub_date = child.content.to_i
              else
                pub_date = Time.parse(child.content).year rescue nil
              end
              history.attributes["pub_date"] = pub_date
              history.attributes["pub_date_sort"] = pub_date
            elsif child.name == "language"
              history.attributes["language_facet"] = child.content
            #elsif child.name == "coverage" # TODO
            #  child_name = child.name + "_t"
            #  history.attributes[child_name] ||= []
            #  history.attributes[child_name] << child.content
            elsif child.name == "subject"
              history.attributes["subject_topic_facet"] ||= []
              history.attributes["subject_topic_facet"] << child.content
              history.attributes["subject_t"] ||= []
              history.attributes["subject_t"] << child.content
            #elsif child.name == "contributor" # TODO

            elsif child.name == "creator"
              history.attributes["author_display"] = child.content
              history.attributes["author_t"] ||= []
              history.attributes["author_t"] << child.content
            else
              history.attributes[child.name + "_display"] = child.content
              history.attributes[child.name + "_t"] ||= []
              history.attributes[child.name + "_t"] << child.content
            end
          end
        end
      end
      puts history.to_solr.inspect
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
    SolrService.commit
  end

  def remove_from_index
    SolrService.delete_by_id(self.id)
    SolrService.commit
  end
end
