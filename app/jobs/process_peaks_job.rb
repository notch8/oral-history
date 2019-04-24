class ProcessPeaksJob < ApplicationJob
  queue_as :peaks

  def perform(*args)
    SolrService.all_records do |ref|
      puts "Creating Peak Job for: #{ref["title_display"]} - #{ref["id"]}"

      ProcessPeakJob.perform_later(ref["id"])
    end
  end
end
