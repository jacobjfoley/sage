class DigitalObjectsController < ApplicationController

  before_action :check_logged_in
  before_action :check_access
  before_action :set_project
  before_action :set_digital_object, only: [:show, :edit, :update, :destroy,
    :add_concept, :remove_concept, :repair_thumbnails, :add_created_concept]
  before_action :set_concept, only: [:add_concept, :remove_concept]

  layout 'control'

  helper ThumbnailHelper

  # Note: minus one for the new object button.
  PAGE_ITEMS = 27

  # GET /digital_objects
  # GET /digital_objects.json
  def index

    # Find the current page.
    page = current_page
    start_index = page * PAGE_ITEMS
    end_index = start_index + PAGE_ITEMS

    # Initialise previous and next pages.
    @previous_page = nil
    @next_page = nil

    # Determine if a previous page is possible.
    if page > 0
      @previous_page = page - 1
    end

    # Determine if a next page is possible.
    if end_index < @project.digital_objects.count
      @next_page = page + 1
    end

    # Retrieve a page of results or an empty array if none.
    @digital_objects = @project.object_index[start_index...end_index] || []
  end

  # GET /digital_objects/1
  # GET /digital_objects/1.json
  def show
    # New concept for quick create.
    @concept = Concept.new

    # Get object listing.
    items = @project.object_index

    # Get index of this object within listing.
    index = items.find_index(@digital_object)

    # Determine relative links.
    @index_page = index / PAGE_ITEMS
    @random_item = items[Random.rand(items.count)].id
    @previous_item = nil
    @next_item = nil

    # Find previous item.
    if index > 0
      @previous_item = items[index - 1].id
    end

    # Find next item.
    if index < (items.count - 1)
      @next_item = items[index + 1].id
    end
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
      saved &= DigitalObject.find_or_create_by(
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
      Annotation.create(
        digital_object_id: @digital_object.id,
        concept_id: @concept.id,
        user_id: session[:user_id],
        provenance: "Existing"
      )
    end

    redirect_to project_digital_object_path(@project, @digital_object)
  end

  # POST /objects/1/add_created_concept
  def add_created_concept

    # Details.
    details = params.require(:concept).permit(:description)
    details[:project_id] = @project.id

    # Create new concept.
    @concept = Concept.find_or_create_by(details)

    # Attempt to save.
    if @concept

      # Associate new concept with this object.
      unless @digital_object.concepts.include? @concept
        Annotation.create(
          digital_object_id: @digital_object.id,
          concept_id: @concept.id,
          user_id: session[:user_id],
          provenance: "New"
        )
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
      @digital_object.concepts.destroy @concept
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

    # Find the index of the first object in this page.
    def current_page

      # Clean and retrieve page param.
      /(?<page>\d+)/ =~ params[:page]

      # Check for no page.
      if !page

        # Default to zero.
        page = 0
      end

      # Return page.
      return page.to_i
    end
end
