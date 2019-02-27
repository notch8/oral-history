class AdminController < ApplicationController
  before_action :authenticate_user!
  
  def index
  end

  def run_import
    @job = Delayed::Job.enqueue ImportRecordsJob.new
  end
end
