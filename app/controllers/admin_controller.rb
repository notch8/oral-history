class AdminController < ApplicationController
  before_action :authenticate_user!
  
  def index
  end

  def run_import
    OralHistoryItem.import({ progress: false })
  end

end
