class ConceptsController < ApplicationController
  before_action :set_project
  before_action :set_concept
  before_action :check_access

  layout 'control'

  PAGE_ITEMS = 100

  # GET /concepts
  # GET /concepts.json
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
    if end_index < (@project.concepts.count - 1)
      @next_page = page + 1
    end

    # Retrieve a page of results or an empty array if none.
    @concepts = @project.concept_index[start_index...end_index] || []
  end

  # GET /concepts/1
  # GET /concepts/1.json
  def show

    # Get item listing.
    items = @project.concept_index

    # Get index of this item within listing.
    index = items.find_index(@concept)

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

  # GET /concepts/new
  def new
    @concept = Concept.new
  end

  # GET /concepts/1/edit
  def edit
  end

  # POST /concepts
  # POST /concepts.json
  def create

    # Fetch and configure params.
    details = concept_params
    details[:project_id] = @project.id

    # Find or create concept.
    @concept = Concept.find_or_create_by(details)

    respond_to do |format|
      if @concept
        format.html { redirect_to new_project_concept_path(@project), notice: 'Concept was successfully created.' }
        format.json { render action: 'show', status: :created, location: @concept }
      else
        format.html { render action: 'new' }
        format.json { render json: @concept.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /concepts/1
  # PATCH/PUT /concepts/1.json
  def update
    respond_to do |format|
      if @concept.update(concept_params)
        format.html { redirect_to [@project, @concept], notice: 'Concept was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @concept.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /concepts/1
  # DELETE /concepts/1.json
  def destroy
    @concept.destroy
    respond_to do |format|
      format.html { redirect_to project_concepts_url }
      format.json { head :no_content }
    end
  end

  # POST /concepts/1/add_object
  def add_object
    set_object

    unless @concept.digital_objects.include? @object
      Annotation.create(
        digital_object_id: @object.id,
        concept_id: @concept.id,
        user_id: session[:user_id],
        provenance: "Existing"
      )
    end

    redirect_to project_concept_path(@project, @concept)
  end

  # POST /concepts/1/remove_object
  def remove_object
    set_object

    if @concept.digital_objects.include? @object
      @concept.digital_objects.destroy @object
    end

    redirect_to project_concept_path(@project, @concept)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_concept

      # If the params contains an id.
      if params[:id]

        # Set the concept.
        @concept = Concept.find(params[:id])
      end
    end

    # Get the digital object object.
    def set_object
      @object = DigitalObject.find(params[:object_id])
    end

    # Get the project that the concept belongs to.
    def set_project
      @project = Project.find(params[:project_id])
    end

    # Get the role of the user in this project.
    def set_user_role
      @user_role = UserRole.find_by(user_id: session[:user_id], project_id: params[:project_id])
    end

    # Ensure that the user has appropriate access privileges for what they are accessing.
    def check_access

      # Check if the user is logged in.
      if !@user
        flash[:notice] = "You are not logged in. Please log in to continue."
        redirect_to login_users_path
      end

      # Get the user's role in this project.
      set_user_role

      # Check user's role.
      if @user_role.nil?

        # User doesn't have a role in this project.
        flash[:notice] = "You don't have access to this project."
        redirect_to projects_path
      end

      # Define priviledges.
      view = ["show", "index"]
      edit = ["new", "create", "update", "edit", "destroy", "add_object",
        "remove_object", "create_from_object"]

      # Allocate priviledges to roles.
      priviledges = {
        "Viewer" => view,
        "Contributor" => view + edit,
        "Administrator" => view + edit
      }

      # Allow requests with correct permissions.
      if priviledges[@user_role.position].include? params[:action]
        return true
      end

      # Otherwise, no permissions.
      redirect_to "/403.html"
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def concept_params
      params.require(:concept).permit(:description)
    end

    # Find the index of the first entry in this page.
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
