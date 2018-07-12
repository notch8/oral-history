desc "process all solr documents' audio peaks"
task peaks: [:environment] do
  SolrService.all_records do |ref|
    puts "Processing peaks for: #{ref["title_display"]} - #{ref["id"]}"

    OralHistoryItem.find(ref["id"]).generate_peaks
  end
end
