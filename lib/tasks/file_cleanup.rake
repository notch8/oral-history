desc 'clean up old files in tmp directory'
task :file_cleanup => [:environment] do
  FileCleanupJob.perform_now
end
