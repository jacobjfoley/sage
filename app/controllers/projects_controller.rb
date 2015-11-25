require 'csv'

class ProjectsController < ApplicationController
  before_action :set_project
  before_action :check_access

  layout 'control', except: [:new, :create, :index, :redeem_key, :check_key]

  # GET /receive_oauth2
  def receive_oauth2

    # Get the project id passed in state.
    project_id = params[:state]

    # Check whether the call was successful.
    if params[:error].eql? "access_denied"

      # Unsuccessful. Redirect to project with notice.
      notice = "SAGE was declined access to Google Drive."

    else

      # Get access code.
      code = params[:code]

      # Commence exchange process.
      begin

        # Exchange authorisation code for access token.
        authorisation = GoogleDriveUtils.exchange_code(code)

        # Store authorisation in session.
        session[:access_token] = authorisation.access_token

        # Notify of success.
        notice = "SAGE has been granted temporary access to Google Drive."

      # Rescue from expired code issues.
      rescue CodeExchangeError

        # Notify of error.
        notice = "An issue was encountered while requesting access to Google Drive."
      end
    end

    # Redirect the user.
    redirect_to new_project_digital_object_path(project_id), notice: notice
  end

  # GET /projects/1/import_annotations
  # POST /projects/1/import_annotations
  def import_annotations

    # If receiving data:
    if request.post?

      # Process data.
      begin

        # Call method.
        @project.import_annotations(params[:data], params[:import_method], @user)

        # Redirect back to project path.
        flash.notice = "You have successfully imported the annotations."
        redirect_to project_path(@project)

      rescue CSV::MalformedCSVError

        # Rescue from malformed CSV data.
        flash.alert = "The supplied data was not in valid CSV format."
        redirect_to import_annotations_project_path(@project)

      rescue RuntimeError => e

        # Rescue from error.
        flash.alert = e.message
        redirect_to import_annotations_project_path(@project)
      end
    end
  end

  # GET /projects/1/export_annotations
  # POST /projects/1/export_annotations
  def export_annotations

    # If receiving data:
    if request.post?

      # Fetch the complete array of rows of data to export.
      @data = @project.export_annotations(
        params[:export_mode],
        params[:export_format]
      )
    end
  end

  # GET /projects
  # GET /projects.json
  def index
    @projects = @user.projects.order(:name)
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @admins = administrator_count

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

  # POST /projects/1/remove_user
  def remove_user

    # Fetch user role.
    role = UserRole.find_by(
      user_id: params[:removed_user_id],
      project_id: @project.id
    )

    # Check for deleting administrators.
    unless role.position.eql? "Administrator"

      # If not administrator, destroy role.
      role.destroy
    end

    # Redirect back to project.
    redirect_to project_path(@project)
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy

    # Remove the user's role from this project.
    @user_role.destroy

    # Check number of admins for deletion method.
    if UserRole.where(project_id: @project.id, position: "Administrator").count == 0

      # Destroy entire project.
      @project.destroy
    end

    # Redirect.
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

  # GET /projects/1/statistics
  def statistics

    # Get the project's statistics.
    @statistics = Statistics.new(@project.id)
    @object_statistics = @statistics.object_statistics
    @concept_statistics = @statistics.concept_statistics
    @word_statistics = @statistics.word_statistics
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project

      # If the params contains an id:
      if params[:id]

        # Check if the project exists.
        if Project.exists?(params[:id])

          # Set the project.
          @project = Project.find(params[:id])
        else

          # Redirect on error.
          flash[:alert] = "The specified project was not found."
          redirect_to projects_path
        end
      end
    end

    # Set the user role.
    def set_user_role
      @user_role = UserRole.where(user_id: @user.id, project_id: @project.id).first
    end

    # Find how many administrators are in the current project.
    def administrator_count

      # Return the number of administrators.
      return UserRole.where(project_id: @project.id, position:"Administrator").count
    end

    # Check authorisation before access.
    def check_access

      # Check if the user is logged in.
      if !@user
        flash[:notice] = "You are not logged in. Please log in to continue."
        redirect_to login_users_path
        return false
      end

      # Define public (for logged in users) pages.
      public_pages = ["new", "create", "index", "redeem_key", "check_key",
        "receive_oauth2"]

      # Allow user to access public pages.
      if public_pages.include? params[:action]
        return true
      end

      # Get the user's role in this project.
      set_user_role

      # Check user's role.
      if @user_role.nil?

        # User doesn't have a role in this project.
        flash[:notice] = "You don't have access to this project."
        redirect_to projects_path
        return false
      end

      # Define priviledges.
      view = ["show", "destroy", "statistics", "export_annotations"]
      admin = ["update", "edit", "generate_key", "reset_key", "remove_user",
      "import_annotations"]

      # Allocate priviledges to roles.
      priviledges = {
        "Viewer" => view,
        "Annotator" => view,
        "Contributor" => view,
        "Administrator" => view + admin
      }

      # Allow requests with correct permissions.
      if priviledges[@user_role.position].include? params[:action]
        return true
      end

      # Otherwise, no permissions.
      redirect_to "/403.html"
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def project_params
      params.require(:project).permit(:name, :notes, :algorithm)
    end
end
