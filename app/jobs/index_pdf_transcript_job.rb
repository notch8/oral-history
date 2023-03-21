require 'shellwords'

class IndexPdfTranscriptJob < ApplicationJob
  queue_as :default

  def perform(id, pdf_text)
    puts "Processing pdf: #{id}"
    #find history
    item = OralHistoryItem.find_or_new(id)
    # make call to solr for extraction
    tmp_file = Tempfile.new

    tmp_file.binmode
    `curl -o #{tmp_file.path} #{pdf_text}`

    if tmp_file.size > 0
      result = SolrService.extract(path: tmp_file.path)
      # put response in this field
      item.attributes['transcripts_t'] ||= []
      item.attributes['transcripts_t'] << result[File.basename(tmp_file.path)].to_s.strip
      item.index_record
    end
  end
end
