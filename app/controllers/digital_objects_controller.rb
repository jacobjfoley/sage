class DigitalObjectsController < ApplicationController

  # Callbacks.
  before_action :check_logged_in
  before_action :check_access
  before_action :set_project
  before_action :set_digital_object, only: [:show, :edit, :update, :destroy,
    :add_concept, :remove_concept, :repair_thumbnails, :add_created_concept]
  before_action :set_concept, only: [:add_concept, :remove_concept]

  # Layout.
  layout 'control'

  # Helpers.
  helper ThumbnailHelper

  # GET /digital_objects
  # GET /digital_objects.json
  def index

    # Fetch the project's digital objects sorted by concept count.
    @digital_objects = DigitalObject.ranked(@project)
  end

  # GET /digital_objects/1
  # GET /digital_objects/1.json
  def show
    @concept = Concept.new
  end

  # GET /digital_objects/new
  def new
    @digital_object = DigitalObject.new
    @have_google_authorisation = session[:access_token]
    @google_authorisation_uri = GoogleDriveUtils.get_authorization_url(@project.id)
  end

  # GET /digital_objects/1/edit
  def edit
  end

  # POST /digital_object/1/repair_thumbnails
  def repair_thumbnails

    # Call method on object.
    @digital_object.repair_thumbnails

    # Redirect back to object.
    redirect_to project_digital_object_path(@project, @digital_object)
  end

  # POST /digital_objects
  # POST /digital_objects.json
  def create

    # Get location list.
    locations = digital_object_params[:location].lines

    # Flag to test whether new object could be saved.
    saved = true;

    # Modify params for each location, and use them to create objects.
    locations.each do |location|

      # Create digital object.
      saved &= DigitalObject.create(
        project_id: @project.id,
        location: location.chomp
      )
    end

    # Set notice.
    if locations.count > 1 && saved
      notice = "Digital objects were successfully created."
    elsif saved
      notice = "Digital object was successfully created."
    end

    respond_to do |format|
      if saved
        format.html { redirect_to project_digital_objects_path, notice: notice }
        format.json { render action: 'index', status: :created, location: @digital_object }
      else
        format.html { render action: 'new' }
        format.json { render json: @digital_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /digital_objects/1
  # PATCH/PUT /digital_objects/1.json
  def update
    respond_to do |format|
      if @digital_object.update(digital_object_params)
        format.html { redirect_to [@project, @digital_object], notice: 'Digital object was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @digital_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /digital_objects/1
  # DELETE /digital_objects/1.json
  def destroy
    @digital_object.destroy
    respond_to do |format|
      format.html { redirect_to project_digital_objects_url }
      format.json { head :no_content }
    end
  end

  # POST /objects/1/add_concept
  def add_concept
    unless @digital_object.concepts.include? @concept
      @digital_object.concepts << @concept
    end

    redirect_to project_digital_object_path(@project, @digital_object)
  end

  # POST /objects/1/add_created_concept
  def add_created_concept

    # Create new concept.
    @concept = Concept.new(params.require(:concept).permit(:description))

    # Set the project ID from the parameters passed to this controller.
    @concept.project_id = @project.id

    # Attempt to save.
    if @concept.save

      # Associate new concept with this object.
      unless @digital_object.concepts.include? @concept
        @digital_object.concepts << @concept
      end

      # Redirect with success.
      redirect_to project_digital_object_path(@project, @digital_object)
    else

      # Redirect with failure.
      redirect_to project_digital_object_path(@project, @digital_object),
        notice: 'Concept was not able to be created.'
    end
  end

  # POST /objects/1/remove_object
  def remove_concept
    if @digital_object.concepts.include? @concept
      @digital_object.concepts.delete @concept
    end

    redirect_to project_digital_object_path(@project, @digital_object)
  end

  # POST /objects/1/import_drive_folder
  def import_drive_folder

    # Get the specified folder.
    folder = params[:drive_folder]

    begin

      # Import folder.
      notice = GoogleDriveUtils.import_drive_folder(
        folder,
        @project.id,
        session[:access_token]
      )

    rescue ExpiredAuthError

      # Set notice and expire access_token.
      notice = "Your authorisation of SAGE to access Google Drive has " +
        "expired. Please renew authorisation to continue."
      session[:access_token].delete
    end

    # Redirect to object listing.
    redirect_to project_digital_objects_path(@project),
      notice: notice
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_digital_object
      @digital_object = DigitalObject.find(params[:id])
    end

    def set_concept
      @concept = Concept.find(params[:concept_id])
    end

    def set_project
      @project = Project.find(params[:project_id])
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
      viewer_pages = ["show", "index"]
      contributor_pages = ["show", "index", "new", "create", "update", "edit",
        "destroy", "add_concept", "remove_concept", "repair_thumbnails",
        "add_created_concept", "import_drive_folder"
      ]
      administrator_pages = ["show", "index", "new", "create", "update", "edit",
         "destroy", "add_concept", "remove_concept", "repair_thumbnails",
         "add_created_concept", "import_drive_folder"
      ]

      # Get the currently logged-in user's role in this project, if any.
      @role = UserRole.find_by(user_id: session[:user_id], project_id: params[:project_id])

      # Check if a role exists.
      if @role.nil?

        # User doesn't have a role in this project.
        redirect_to "/403.html"
      else

        # Filter incorrect permissions.
        if (@role.position.eql? "Viewer") && (viewer_pages.include? params[:action])
        elsif (@role.position.eql? "Contributor") && (contributor_pages.include? params[:action])
        elsif (@role.position.eql? "Administrator") && (administrator_pages.include? params[:action])
        else
          # No permissions.
          redirect_to "/403.html"
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def digital_object_params
      params.require(:digital_object).permit(:location)
    end
end
