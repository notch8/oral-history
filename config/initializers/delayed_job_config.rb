Delayed::Job.destroy_failed_jobs = false

silence_warnings do
  Delayed::Job.const_set("MAX_ATTEMPTS", 10)
  Delayed::Job.const_set("MAX_RUN_TIME", 30.minutes)
end
