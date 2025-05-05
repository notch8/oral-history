# Ensure job classes are loaded early
require Rails.root.join('app/jobs/import_full_records_job')
require Rails.root.join('app/jobs/import_single_record_job')

Rails.application.config.to_prepare do
  if defined?(Delayed::Worker) && Delayed::Worker.respond_to?(:yaml_safe_load_permitted_classes)
    Delayed::Worker.yaml_safe_load_permitted_classes += [
      ImportFullRecordsJob,
      ImportSingleRecordJob,
      ActiveSupport::HashWithIndifferentAccess
    ]
  end
end

# Optional: configure worker behavior
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.queue_attributes = {
  default: { priority: -10 },
  peaks: { priority: 10 }
}
silence_warnings do
  Delayed::Job.const_set("MAX_ATTEMPTS", 10)
  Delayed::Job.const_set("MAX_RUN_TIME", 4.hours)
end
Delayed::Worker.max_run_time = 4.hours
Delayed::Worker.logger = Logger.new(Rails.root.join('log', 'worker.log'))
