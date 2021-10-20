class AdminController < ApplicationController
  before_action :authenticate_user!

  def index
    @job_running = OralHistoryItem.check_for_tmp_file
  end

  def run_import
    @job = Delayed::Job.enqueue ImportRecordsJob.new(delete: params[:delete])
  end

  def logs
    send_file(Rails.root.join('log/indexing.log'))
  end
end
