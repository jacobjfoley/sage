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

    # If a user id has been stored in the session:
    if session[:user_id]

      # Set the user based on the session info.
      @user = User.find(session[:user_id])
    end
  end
end
