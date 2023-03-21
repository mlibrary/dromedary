class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout "blacklight"

  protect_from_forgery with: :exception

  before_action :store_request_in_thread

  def store_request_in_thread
    Thread.current[:request] = request
  end
end
