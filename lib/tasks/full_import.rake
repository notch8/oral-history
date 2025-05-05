namespace :oral_history do
  desc 'Clear all records from Solr'
  task :clear_solr => [:environment] do
    SolrService.remove_all
  end

  desc 'Import all records from OAI-PMH feed'
  task :import_all, [:limit, :progress] => [:environment] do |_, args|
    args ||= {}
    limit = (args[:limit] || 20_000_000).to_i
    progress = args[:progress].to_s != 'false' # default to true unless explicitly false

    OralHistoryItem.full_import(limit: limit, progress: progress)
  end
end
