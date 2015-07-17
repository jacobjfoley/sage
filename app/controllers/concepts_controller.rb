class ConceptsController < ApplicationController
  before_action :check_logged_in
  before_action :check_access
  before_action :set_project
  before_action :set_concept, only: [:show, :edit, :update, :destroy, :add_object, :remove_object]
  before_action :set_object, only: [:add_object, :remove_object, :create_from_object]

  layout 'control'

  # GET /concepts
  # GET /concepts.json
  def index

    # Fetch the project's concepts sorted by association count.
    @concepts = Concept.ranked(@project.id)
  end

  # GET /concepts/1
  # GET /concepts/1.json
  def show
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
    @concept = Concept.new(concept_params)

    # Set the project ID from the parameters passed to this controller.
    @concept.project_id = @project.id

    respond_to do |format|
      if @concept.save
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
    unless @concept.digital_objects.include? @object
      @concept.digital_objects << @object
    end

    redirect_to project_concept_path(@project, @concept)
  end

  # POST /concepts/1/remove_object
  def remove_object
    if @concept.digital_objects.include? @object
      @concept.digital_objects.delete @object
    end

    redirect_to project_concept_path(@project, @concept)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_concept
      @concept = Concept.find(params[:id])
    end

    # Get the digital object object.
    def set_object
      @object = DigitalObject.find(params[:object_id])
    end

    # Get the project that the concept belongs to.
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
      contributor_pages = ["show", "index", "new", "create", "update", "edit", "destroy", "add_object", "remove_object", "create_from_object"]
      administrator_pages = ["show", "index", "new", "create", "update", "edit", "destroy", "add_object", "remove_object", "create_from_object"]

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
    def concept_params
      params.require(:concept).permit(:description)
    end
end
