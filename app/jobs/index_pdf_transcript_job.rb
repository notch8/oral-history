class IndexPdfTranscriptJob < ApplicationJob
  queue_as :default

  def perform(id, pdf_text)
    puts "Processing pdf: #{id}"
    #find history
    item = OralHistoryItem.find(id)
    # make call to solr for extraction
    tmp_file = Tempfile.new
    
    tmp_file.binmode
    open(pdf_text) do |url_file|
      tmp_file.write(url_file.read)
    end                
    result = SolrService.extract(path: tmp_file.path)
    # put response in this field
    item.attributes['transcripts_t'] << result[File.basename(tmp_file.path)].to_s.strip

    item.index_record
  end
end
