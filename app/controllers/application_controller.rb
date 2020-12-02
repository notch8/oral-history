class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Blacklight::Catalog
  layout 'blacklight'

  protect_from_forgery with: :exception
  before_action :set_raven_context
  #before_action :authenticate_for_staging

  private
  def authenticate_for_staging
    if ENV['USE_HTTP_BASIC'] && !request.format.to_s.match('json') && !params[:print] && !request.path.include?('api') && !request.path.include?('pdf')
      authenticate_or_request_with_http_basic do |username, password|
        username == "oralhistory" && password == "oralhistory"
      end
    end
  end

  def set_raven_context
    Raven.user_context(id: session[:current_user_id]) # or anything else in session
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
end
