class ImportRecordsJob < ProgressJob::Base

  def perform
    update_stage('Importing Records')
    update_progress_max(OralHistoryItem.total_records)
    OralHistoryItem.import({ progress: false }) do |total|
      update_progress
    end
  end
end