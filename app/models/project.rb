require "securerandom"

class Project < ActiveRecord::Base

  # Associations with other models.
  has_many :concepts, dependent: :destroy
  has_many :digital_objects, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  has_many :associations, dependent: :destroy

  # Validations.
  validates :name, presence: true, length: { minimum: 1 }
  validates :viewer_key, uniqueness: true, allow_nil: true
  validates :contributor_key, uniqueness: true, allow_nil: true
  validates :administrator_key, uniqueness: true, allow_nil: true

  # Find suggestions based on concept description.
  def disperse(influence, propagations, concept_id)

    # Find all similar concepts to the provided description.
    similar = WordTable.text_similarity(concept_id)

    # Determine total weight in results.
    total = 0.0
    similar.values.each do |value|
      total += value
    end

    # Create results hash.
    results = {}

    # If total is greater than zero:
    if total > 0

      # Distribute influence according to similarity score.
      similar.keys.each do |key|
        similar[key] *= influence / total
      end

      # For each similar result:
      similar.keys.each do |key|

        # Find concept.
        concept = Concept.find(key)

        # Call each similar concept with their portion of total influence.
        response = concept.collaborate(similar[key], propagations, true)

        # Assimilate response.
        aggregate(results, response)
      end
    end

    # Return end result.
    return results
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
      all_keys[project.administrator_key] = {project: project, position: "Administrator"}
    end

    # Check if provided key is present.
    if (all_keys.key?(key) && !(key.nil?))

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
      my_object = DigitalObject.create(
        project_id: id,
        location: other_object.location,
        thumbnail_url: other_object.thumbnail_url
      )

      # Add to mapping.
      object_mapping[other_object.id] = my_object.id
    end

    # For each concept in the original project:
    other_project.concepts.each do |other_concept|

      # Create a copy of the concept.
      my_concept = Concept.create(
        project_id: id,
        description: other_concept.description
      )

      # Add to mapping.
      concept_mapping[other_concept.id] = my_concept.id
    end

    # Link new concepts and objects.
    Association.where(project_id: other_project_id).each do |association|

      # Create new association.
      Association.create(
        digital_object_id: object_mapping[association.digital_object_id],
        concept_id: concept_mapping[association.concept_id],
        user_id: association.user_id
      )
    end
  end

  private

  # Aggregate a response with the in-progress results hash.
  def aggregate(results, response)

    # For each element in the response:
    response.keys.each do |key|

      # If the key is already in the results:
      if results.key? key

        # Add to the key's influence.
        results[key] += response[key]
      else

        # Introduce key to results with its influence.
        results[key] = response[key]
      end
    end
  end
end
