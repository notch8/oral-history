class AdminController < ApplicationController
  before_action :authenticate_user!
  
  def index
  end

  def run_import
    puts "Import job should run here"
    @job = Delayed::Job.enqueue ImportRecordsJob.new
    Rails.logger.info @job.inspect
  end
end
