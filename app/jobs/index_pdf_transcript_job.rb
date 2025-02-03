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
    escaped_pdf_text = Shellwords.escape(pdf_text)
    cmd = "curl -o #{tmp_file.path} #{escaped_pdf_text}"
    system(cmd)

    if tmp_file.size > 0
      result = SolrService.extract(path: tmp_file.path)
      transcript = result['file'].to_s.strip

      # put transcript into these fields
      item.attributes['transcripts_t'] ||= []
      item.attributes['transcripts_t'] << transcript
      item.attributes['transcripts_json_t'] ||= []
      item.attributes['transcripts_json_t'] << {
        'transcript_t': transcript
      }.to_json

      # index the record in Solr
      item.index_record
    end
  end
end
