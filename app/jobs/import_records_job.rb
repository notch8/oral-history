class ImportRecordsJob < ProgressJob::Base
  def initialize(args = {})
    @args = args
  end

  def perform
    update_stage('Importing Records')
    update_progress_max(OralHistoryItem.total_records) unless OralHistoryItem.total_records.nil?
    OralHistoryItem.import({ limit: 20000000, progress: false }.merge(@args)) do |total|
      update_progress
    end
  end
end
