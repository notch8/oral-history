desc 'clear solr of records'
task :clear => [:environment] do
  SolrService.remove_all
end

desc 'import all records via oai-pmh'
task :import, [:limit, :progress] => [:environment] do |t, args|
  progress = args[:progress] || true
  limit = args[:limit] || 20000000
  limit = limit.to_i
  OralHistoryItem.import(limit: limit)
end
