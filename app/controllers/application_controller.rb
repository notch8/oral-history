class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Blacklight::Catalog
  layout 'blacklight'

  protect_from_forgery with: :exception
end
