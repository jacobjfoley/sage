class DigitalObjectsController < ApplicationController
  before_action :check_logged_in
  before_action :check_access
  before_action :set_project
  before_action :set_digital_object, only: [:show, :edit, :update, :destroy, :add_concept, :remove_concept]
  before_action :set_concept, only: [:add_concept, :remove_concept]

  layout 'control'

  # GET /digital_objects
  # GET /digital_objects.json
  def index
    @digital_objects = @project.digital_objects.sort_by(&:updated_at).reverse
  end

  # GET /digital_objects/1
  # GET /digital_objects/1.json
  def show
  end

  # GET /digital_objects/new
  def new
    @digital_object = DigitalObject.new
  end

  # GET /digital_objects/1/edit
  def edit
  end

  # POST /digital_objects
  # POST /digital_objects.json
  def create

    # Flag to test whether new object could be saved.
    saved = true;

    # Determine if adding a batch or single entry.
    if digital_object_params[:location].lines.count == 1

      # Single entry. Create object using params directly.
      @digital_object = DigitalObject.new(digital_object_params)

      # Set the project ID from the parameters passed to this controller.
      @digital_object.project_id = @project.id

      # Save the object.
      saved = @digital_object.save
      
    else
      # Batch entry. Fetch locations.
      locations = digital_object_params[:location].lines

      # Modify params for each location, and use them to create objects.
      locations.each do |loc|
        params[:digital_object][:location] = loc.chomp
        @digital_object = DigitalObject.new(digital_object_params)

        # Set the project ID from the parameters passed to this controller.
        @digital_object.project_id = @project.id

        saved &= @digital_object.save
      end
    end

    respond_to do |format|
      if saved
        format.html { redirect_to [@project, @digital_object], notice: 'Digital object was successfully created.' }
        format.json { render action: 'show', status: :created, location: @digital_object }
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

  # POST /objects/1/remove_object
  def remove_concept
    if @digital_object.concepts.include? @concept
      @digital_object.concepts.delete @concept
    end

    redirect_to project_digital_object_path(@project, @digital_object)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_digital_object
      @digital_object = DigitalObject.find(params[:id])
    end

    def set_concept
      @concept = Concept.find(params[:concept])
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
      contributor_pages = ["show", "index", "new", "create", "update", "edit", "destroy", "add_concept", "remove_concept"]
      administrator_pages = ["show", "index", "new", "create", "update", "edit", "destroy", "add_concept", "remove_concept"]

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
