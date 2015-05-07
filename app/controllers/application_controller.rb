class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  # Check if a user is logged in.
  before_action :logged_in
  
  # Private methods.
  private
  
  # Check that the user is currently logged in.
    def logged_in
      if session.has_key? :user_id
        @logged_in = true
      else
        @logged_in = false
      end
    end
end
