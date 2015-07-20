class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Check if a user is logged in.
  before_action :set_user_id

  # Private methods.
  private

  # Sets the user, if the user is logged in.
  def set_user_id
    @user_id = session[:user_id]
  end
end
