class ImportSingleRecordJob < ProgressJob::Base
  def initialize(args = {})
    @id = args[:id]
  end

  def perform
    update_stage('Importing Record')
    OralHistoryItem.import_single(@id)
  end
end