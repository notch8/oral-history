desc "process all solr documents' audio peaks"
task peaks: [:environment] do
  peaks = Peaks::Processor.new('public/peaks')

  SolrService.all_records do |ref|
    puts "Processing peaks for: #{ref["title_display"]} - #{ref["id"]}"

    peaks.from_solr_document SolrDocument.find(ref["id"])
  end
end
