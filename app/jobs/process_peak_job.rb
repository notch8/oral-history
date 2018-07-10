class ProcessPeakJob < ApplicationJob
  queue_as :default

  def perform(id)
    peaks = Peaks::Processor.new('public/peaks')
    puts "Processing peaks for: #{id}"

    peaks.from_solr_document SolrDocument.find(id)
  end
end
