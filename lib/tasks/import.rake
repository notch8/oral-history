desc 'import all records via oai-pmh'
task :import, [:limit, :progress] => [:environment] do |t, args|
  progress = args[:progress] || true
  limit = args[:limit] || 20000000
  OralHistoryItem.import(limit: limit)
end
