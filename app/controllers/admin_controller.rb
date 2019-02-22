class AdminController < ApplicationController
  before_action :authenticate_user!
  
  def index

  end

  def run_import
    args ||= {}
    progress = true
    limit = 20000000
    limit = limit.to_i
    OralHistoryItem.import(limit: limit)
  end

end
