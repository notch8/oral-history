class ImportFullRecordsJob
  attr_reader :args

  def initialize(delete:, override:, job_id: nil)
    @args = {
      delete: delete,
      override: override,
      job_id: job_id
    }.with_indifferent_access
  end

  def perform
    job = Delayed::Job.find_by(id: args[:job_id])
    return unless job

    job.update!(
      progress_stage: "Fetching record count...",
      progress_current: 0,
      progress_max: 100
    )

    begin
      response = OralHistoryItem.client(args).list_records(metadata_prefix: 'oai_dc')

      OralHistoryItem.index_logger.info("🟢 Starting total_records fetch...")
      total_expected = OralHistoryItem.total_records_from_response(response)
      OralHistoryItem.index_logger.info("🟢 Total records to import: #{total_expected}")
      OralHistoryItem.index_logger.info("🟢 Finished total_records fetch.")

      job.update!(
        progress_stage: "Starting import",
        progress_current: 0,
        progress_max: total_expected
      )

      OralHistoryItem.full_import(response, args.merge(total_expected: total_expected)) do |count, is_last|
        job.update(progress_current: count)
        job.update(progress_max: count) if is_last
      end

      OralHistoryItem.index_logger.info("✅ Full import of #{total_expected} records completed successfully")
    rescue => e
      job.update!(
        progress_stage: "❌ Error fetching record count. Check logs.",
        progress_current: 0,
        progress_max: 1
      )
      Rollbar.error(e) if defined?(Rollbar)
      OralHistoryItem.index_logger.error("🛑 OAI fetch failed: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
      raise e
    end
  end
end
