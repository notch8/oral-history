class ProcessPeakJob < ApplicationJob
  queue_as :default

  def perform(id)
    puts "Processing peaks for: #{id}"
    OralHistoryItem.find(id).generate_peaks
  end
end
