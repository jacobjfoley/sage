class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy, :generate_key, :reset_key]
  before_action :check_logged_in
  before_action :set_user, only: [:show, :create, :index, :check_key, :check_access]
  before_action :set_user_role, only: [:show]
  before_action :set_user_lists, only: [:show]
  before_action :check_access, except: [:new, :create, :index, :redeem_key, :check_key]
  
  layout 'control', except: [:new, :create, :index, :redeem_key, :check_key]

  # GET /projects
  # GET /projects.json
  def index
    @projects = @user.projects
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
  end

  # GET /projects/new
  def new
    @project = Project.new
  end

  # GET /projects/1/edit
  def edit
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(project_params)

    respond_to do |format|
      if @project.save
        # Project is initially registered to the creating user.
        UserRole.create user_id: @user.id, project_id: @project.id, position: "Administrator"
      
        format.html { redirect_to @project, notice: 'Project was successfully created.' }
        format.json { render action: 'show', status: :created, location: @project }
      else
        format.html { render action: 'new' }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project.destroy
    respond_to do |format|
      format.html { redirect_to projects_url }
      format.json { head :no_content }
    end
  end

  # GET /projects/redeem_key
  def redeem_key
  end

  # POST /projects/1/generate_key?type=Viewer
  def generate_key
  
    # Generate a new key for the project.
    @project.generate_key(params[:type])
    
    # Save project with new details.
    @project.save
    
    # Redirect back to the project.
    redirect_to @project
  end
  
  # POST /projects/1/reset_key?type=Viewer
  def reset_key
  
    # Reset the given key.
    @project.reset_key(params[:type])
    
    # Save the changes.
    @project.save
    
    # Redirect back to the project.
    redirect_to @project
  end
  
  # POST /projects/check_key?key=sdafasddsfsfasfasfdafdaf
  def check_key
    flash.notice = Project.check_key(params[:key], @user)
    redirect_to redeem_key_projects_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.find(params[:id])
    end
    
    # Set the user.
    def set_user
      @user = User.find(session[:user_id])
    end
    
    # Set the user role.
    def set_user_role
      @user_role = UserRole.where(user_id: @user.id, project_id: @project.id).first
    end
    
    # Set listings of users.
    def set_user_lists
    
      @administrators = []
      @contributors = []
      @viewers = []
    
      UserRole.where(project_id: @project.id, position: "Administrator").each do |role|
        @administrators << User.find(role.user_id)
      end
      
      UserRole.where(project_id: @project.id, position: "Contributor").each do |role|
        @contributors << User.find(role.user_id)
      end
      
      UserRole.where(project_id: @project.id, position: "Viewer").each do |role|
        @viewers << User.find(role.user_id)
      end      
    end

    # Ensure that the user is currently logged in.
    def check_logged_in
      if !session.has_key? :user_id

        # Provide error message and redirect to login page.
        flash[:notice] = "You are not permitted to access this page. Please log in to continue."
        redirect_to login_users_path
      end
    end

    # Ensure that the user has appropriate access privileges for what they are accessing.
    def check_access
    
      # Define the pages which can be accessed using each level of security.
      viewer_pages = ["show"]
      contributer_pages = ["show"]
      administrator_pages = ["show", "update", "edit", "destroy", "generate_key", "reset_key"]
      
      # Get the currently logged-in user's role in this project, if any.
      @role = UserRole.find_by(user_id: session[:user_id], project_id: params[:id])
      
      # Check if a role exists.
      if @role.nil?
      
        # User doesn't have a role in this project.
        redirect_to "/500.html"
      else
      
        # Filter incorrect permissions.
        if (@role.position.eql? "Viewer") && (viewer_pages.include? params[:action])
        elsif (@role.position.eql? "Contributer") && (contributer_pages.include? params[:action])
        elsif (@role.position.eql? "Administrator") && (administrator_pages.include? params[:action])
        else
          # No permissions.
          redirect_to "/404.html"
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def project_params
      params.require(:project).permit(:name, :notes)
    end
end
