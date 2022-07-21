desc 'clean up old files in tmp directory'
task :file_cleanup => [:environment] do
  FileCleanup.purge_files
end
