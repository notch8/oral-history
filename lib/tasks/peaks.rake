desc "process audio peaks"
task peaks: [:environment] do
  solr = SolrService.connect

  pks = Peaks::Processor.new('public/peaks', 1000)

  page_size = 1000
  cursor = 0

  res = solr.get 'select', params: { start: cursor, rows: page_size }
  remaining_records = res["response"]["numFound"].to_i

  # first page
  res["response"]["docs"].each do |ref|
    puts "#{ref["title_display"]} #{ref["id"]}"

    doc = SolrDocument.find ref["id"]

    if doc["children_t"]
      doc["children_t"].each do |child|
        if JSON.parse(child)["url_t"]
          pl = JSON.parse(child)["url_t"]
          id = JSON.parse(child)["id_t"].gsub('/', '-')

          pks.generate(pl, "#{id}.json")
        end
      end
    end

    remaining_records -= 1
  end

  while remaining_records > 0
    res = solr.get 'select', params: { start: cursor, rows: page_size }

    res["response"]["docs"].each do |ref|
      puts "#{ref["title_display"]} #{ref["id"]}"

      doc = SolrDocument.find ref["id"]

      if doc["children_t"]
        doc["children_t"].each do |child|
          if JSON.parse(child)["url_t"]
            pl = JSON.parse(child)["url_t"]
            id = JSON.parse(child)["id_t"].gsub('/', '-')

            pks.generate(pl, "#{id}.json")
          end
        end
      end

      remaining_records -= 1
    end

    cursor += page_size
  end
end
