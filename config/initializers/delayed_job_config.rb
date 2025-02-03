Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.queue_attributes = {
  default: { priority: -10 },
  peaks: { priority: 10 }
}
silence_warnings do
  Delayed::Job.const_set("MAX_ATTEMPTS", 10)
  Delayed::Job.const_set("MAX_RUN_TIME", 4.hours)
  Delayed::Worker.max_run_time = 4.hours
end
