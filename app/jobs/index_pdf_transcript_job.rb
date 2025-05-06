require 'shellwords'

class IndexPdfTranscriptJob < ApplicationJob
  queue_as :default

  def perform(id, pdf_url)
    puts "Processing pdf: #{id}"
    item = OralHistoryItem.find_or_new(id)

    Tempfile.create(['transcript', '.pdf']) do |tmp_file|
      tmp_file.binmode
      escaped_url = Shellwords.escape(pdf_url)
      system("curl -fsSL -o #{tmp_file.path} #{escaped_url}")

      if tmp_file.size.positive?
        result = SolrService.extract(path: tmp_file.path)
        transcript = result['file'].to_s.strip

        item.attributes['transcripts_t'] ||= []
        item.attributes['transcripts_t'] << transcript

        item.attributes['transcripts_json_t'] ||= []
        item.attributes['transcripts_json_t'] << { 'transcripts_t': transcript }.to_json

        item.index_record
      else
        Rails.logger.error("Failed to download PDF for #{id}: file was empty or download failed.")
      end
    end
  end
end
