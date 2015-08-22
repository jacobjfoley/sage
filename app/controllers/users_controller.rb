class UsersController < ApplicationController
  before_action :check_access

  # GET /users
  # GET /users.json
  def index
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    # Check participation details were set.
    if (params[:participant_information] && params[:participation] && params[:age])
      respond_to do |format|
        if @user.save

          # Log in as new user.
          session[:user_id] = @user.id

          format.html { redirect_to projects_path, notice: I18n.t(:user_welcome_message) }
          format.json { render action: 'show', status: :created, location: @user }
        else
          format.html { render action: 'new' }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    else
      @user.errors[:base] << "Please confirm your participation details."
      render action: 'new'
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end

  # GET /users/login
  # POST /users/login
  def login

    # Check for the type of request.
    if request.get?

      # Initial request to login. Provide form.
      @user = User.new
    else
      # Check details in form and determine if the user will be logged in.

      # See if the provided email address exists.
      @user = User.find_by email: params[:user][:email]

      # Check password, if user exists.
      if !@user.nil? && (@user.authenticate params[:user][:password])

        # User exists and password is correct. Log in.
        flash[:notice] = "You have successfully logged in."
        session[:user_id] = @user.id

        # Redirect to the user's project page.
        redirect_to projects_path
      else

        # Incorrect password, or the user doesn't exist. Back to login page.
        @user = User.new
        @user.errors[:base] << "Incorrect email address or password."
      end
    end
  end

  # GET /users/logout
  def logout

    # Reset the session.
    reset_session

    # Redirect to main page.
    redirect_to "/"
  end

  private

    # Check authorisation before access.
    def check_access

      # Define public pages.
      public_pages = ["new", "create", "login", "logout"]

      # Allow user to access public pages.
      if public_pages.include? params[:action]
        return true
      end

      # Check if the user is logged in.
      if !@user
        flash[:notice] = "You are not logged in. Please log in to continue."
        redirect_to login_users_path
      end

      # Define private pages.
      private_pages = ["show", "edit", "update", "destroy"]

      # Allow the user to access private user pages.
      if (private_pages.include? params[:action]) && (@user.id.to_s.eql? params[:id])
        return true
      end

      # Otherwise, no permissions.
      redirect_to "/403.html"
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name, :email, :password)
    end
end
