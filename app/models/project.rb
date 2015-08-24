require "securerandom"

class Project < ActiveRecord::Base

  has_many :concepts, dependent: :destroy
  has_many :digital_objects, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  has_many :annotations, dependent: :destroy
  has_many :children, class_name: "Project", foreign_key: "parent_id"
  belongs_to :parent, class_name: "Project"

  validates :name, presence: true, length: { minimum: 1 }
  validates :viewer_key, uniqueness: true, allow_nil: true
  validates :contributor_key, uniqueness: true, allow_nil: true
  validates :administrator_key, uniqueness: true, allow_nil: true

  SAMPLE_SIZE = 25

  # Retrieve objects, reverse creation order.
  def object_index
    return digital_objects.order(:created_at).to_a.reverse
  end

  # Retrieve concepts, alphabetical order.
  def concept_index
    return concepts.order(:description).to_a
  end

  # Find most popular concepts.
  def popular_concepts(influence)

    # Declare results hash.
    results = {}

    # Determine count of each concept.
    concepts.each do |concept|
      results[concept] = concept.digital_objects.count + 1.0
    end

    # Determine count total.
    total = 0.0
    results.values.each do |value|
      total += value
    end

    # Distribute influence accordingly.
    results.keys.each do |key|
      results[key] *= (influence / total)
    end

    # Return results.
    return results
  end

  # Find most popular objects.
  def popular_objects(influence)

    # Declare results hash.
    results = {}

    # Determine count of each object.
    digital_objects.each do |object|
      results[object] = object.concepts.count + 1.0
    end

    # Determine count total.
    total = 0.0
    results.values.each do |value|
      total += value
    end

    # Distribute influence accordingly.
    results.keys.each do |key|
      results[key] *= influence / total
    end

    # Return results.
    return results
  end

  # Generate a new access key.
  def generate_key(type)

    # Create global list of keys.
    all_keys = []
    Project.all.each do |project|
      all_keys << project.viewer_key
      all_keys << project.contributor_key
      all_keys << project.administrator_key
      all_keys << project.annotator_key
    end

    # Initialise key to not unique.
    key = nil
    unique = false

    # Continue generating and checking keys until a unique key is generated.
    while !unique

      # Generate a new key.
      key = SecureRandom.urlsafe_base64

      # Check for uniqueness across database.
      unique = !(all_keys.include? key)
    end

    # Determine which key to assign and set it.
    if (type.eql? "Viewer")
      self.viewer_key = key
    elsif (type.eql? "Contributor")
      self.contributor_key = key
    elsif (type.eql? "Annotator")
      self.annotator_key = key
    elsif (type.eql? "Administrator")
      self.administrator_key = key
    end
  end

  # Reset an access key.
  def reset_key(type)

    # Determine which key to reset, and disable it.
    if (type.eql? "Viewer")
      self.viewer_key = nil
    elsif (type.eql? "Contributor")
      self.contributor_key = nil
    elsif (type.eql? "Annotator")
      self.annotator_key = nil
    elsif (type.eql? "Administrator")
      self.administrator_key = nil
    end
  end

  # Check an access key.
  def self.check_key(key, user)

    # Create global mapping of keys.
    all_keys = {}
    Project.all.each do |project|
      all_keys[project.viewer_key] = {project: project, position: "Viewer"}
      all_keys[project.contributor_key] = {project: project, position: "Contributor"}
      all_keys[project.annotator_key] = {project: project, position: "Annotator"}
      all_keys[project.administrator_key] = {project: project, position: "Administrator"}
    end

    # Check if provided key is present.
    if (all_keys.key?(key) && !(key.nil?))

      # Check for annotator key.
      if all_keys[key][:position].eql? "Annotator"

        # Generate a sample and adjust details to direct to the sample.
        all_keys[key][:project] = all_keys[key][:project].sample(user)
        all_keys[key][:position] = "Contributor"
      end

      # Get details.
      project = all_keys[key][:project]
      position = all_keys[key][:position]

      # Check for prior role.
      prior = UserRole.where(user_id: user.id, project_id: project.id)

      # Assign user role within project if the user has none already.
      if prior.count == 0

        # Create new role.
        UserRole.create(user_id: user.id, project_id: project.id, position: position)

        # Return success.
        return "You have successfully been added to the project."
      else

        # Check for upgrade.
        if position.eql? "Administrator"
          prior.first.update(position: "Administrator")
        elsif (prior.first.position.eql?("Viewer") && position.eql?("Contributor"))
          prior.first.update(position: "Contributor")
        else
          return "You already have an equal or better role in the project."
        end

        # Return success.
        return "You have successfully been promoted in the project."
      end
    else

      # Return error.
      return "Your key does not exist, or no longer exists, in any project."
    end
  end

  # Clone a project.
  def clone(creator)

    # Create an identical project.
    clone = Project.create(
      notes: notes,
      name: "Clone of #{name}"
    )

    # Have the clone pull content from this project.
    clone.pull(self.id)

    # Set up creator as new administrator.
    UserRole.create(
      user_id: creator,
      project_id: clone.id,
      position: "Administrator"
    )

    # Return the clone to caller.
    return clone.id
  end

  # Merge a copy of the contents of another project with this one.
  def pull(other_project_id)

    # Load the other project.
    other_project = Project.find(other_project_id)

    # Initialise mappings, original ids -> copy ids.
    object_mapping = {}
    concept_mapping = {}

    # For each object in the original project:
    other_project.digital_objects.each do |other_object|

      # Create a copy of the object.
      my_object = DigitalObject.find_or_create_by(
        project_id: id,
        location: other_object.location
      ) do |new_object|
        new_object.thumbnail_url = other_object.thumbnail_url
      end

      # Add to mapping.
      object_mapping[other_object.id] = my_object.id
    end

    # For each concept in the original project:
    other_project.concepts.each do |other_concept|

      # Create a copy of the concept.
      my_concept = Concept.find_or_create_by(
        project_id: id,
        description: other_concept.description
      )

      # Add to mapping.
      concept_mapping[other_concept.id] = my_concept.id
    end

    # Link new concepts and objects.
    other_project.annotations.each do |annotation|

      # Create new annotation.
      Annotation.find_or_create_by(
        digital_object_id: object_mapping[annotation.digital_object_id],
        concept_id: concept_mapping[annotation.concept_id]
      ) do |new_annotation|
        new_annotation.user_id = annotation.user_id
        new_annotation.provenance = "Pulled"
      end
    end
  end

  # Create a sample project based on this one.
  def sample(user)

    # Find the sample projects assigned to this user.
    assigned = user.projects.where(parent: self)

    # Check for incomplete sample.
    incomplete = assigned.select { |p| p.annotations.count == 0 }.first

    # If incomplete sample:
    if incomplete

      # Return the incomplete sample.
      return incomplete
    end

    # Define new details.
    count = assigned.count + 1
    sample_name = "[#{user.name}] Sample #{count} of " + name

    # Determine algorithm to use in sample.
    algorithms = ["SAGA", "VotePlus"].shuffle!.sort_by { |algorithm|

      # Count how often this algorithm has been assigned to samples given to
      # this user.
      user.projects.where(parent: self, algorithm: algorithm).count
    }

    # Create a new project with details.
    sample = Project.create(
      name: sample_name,
      notes: notes,
      parent: self,
      algorithm: algorithms.first
    )

    # Assign administrators to sample.
    user_roles.where(position: "Administrator").each do |administrator|

      # Create new admin position in sample for the original admins.
      UserRole.create(
        user: administrator.user,
        project: sample,
        position: "Administrator"
      )
    end

    # Establish potential locations.
    potential = digital_objects.map { |object| object.location }

    # Establish viewed locations.
    assigned.each do |child|
      potential -= child.digital_objects.map { |object| object.location }
    end

    # Randomise potential locations.
    potential.shuffle!

    # Feed select objects to sample.
    potential[0...SAMPLE_SIZE].each do |location|

      # Create new object in sample.
      DigitalObject.create(location: location, project: sample)
    end

    # Return the sample.
    return sample
  end
end
