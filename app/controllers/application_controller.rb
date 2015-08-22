class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Check if a user is logged in.
  before_action :set_user

  # Private methods.
  private

  # Set the user.
  def set_user
    @user = User.find(session[:user_id])
  end
end
