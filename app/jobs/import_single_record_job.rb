# app/jobs/import_single_record_job.rb
class ImportSingleRecordJob < Struct.new(:id)
  def perform
    OralHistoryItem.index_logger.info("🟢 Running import for record ID: #{id}")
    OralHistoryItem.import_single(id)
    OralHistoryItem.index_logger.info("✅ Import completed successfully")
  end
end
