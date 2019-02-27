class ImportRecordsJob < ProgressJob::Base

  def perform
    update_stage('Importing Records')
    update_progress_max(OralHistoryItem.total_records)
    OralHistoryItem.import({ progress: false }) do |total|
      Rails.logger.info "Current: #{total}"
      update_progress
    end
  end
end