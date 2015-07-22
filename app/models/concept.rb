class Concept < ActiveRecord::Base

  # Associations with other models.
  has_many :associations, dependent: :destroy
  has_many :digital_objects, through: :associations
  belongs_to :project

  # Validations.
  validates :description, presence: true

  # Callbacks.
  before_save :check_flatten, if: :description_changed?

  # Returns ranked ordering of concepts by association count.
  def self.ranked(project_id)

    # Get concepts.
    concepts = Concept.where(project: project_id).to_a

    # Sort by association count.
    concepts.sort! {
      |a,b| a.digital_objects.count <=> b.digital_objects.count
    }

    # Return list.
    return concepts
  end

  # Find relevant objects.
  def relevant

    # Calculate influence to spread.
    influence = project.digital_objects.count.to_f

    # Default influence, three steps (find object), hasn't dispersed yet.
    results = collaborate(influence, 3, false)

    # Distribute minimal influence among popular.
    popular = project.popular_objects(1.0)

    # Merge collaboration results with popular.
    aggregate(results, popular)

    # Return sorted results.
    return results.sort_by {|key, value| value}.reverse.to_h
  end

  # Collaborate with other agents to detect relationships within the project.
  def collaborate(influence, propagations, dispersal)

    # Determine what to do.
    # If at the natural end point:
    if propagations == 0

      # Assign influence to self and return.
      return {self => influence}

    # If dispersal hasn't occurred yet:
    elsif dispersal == false

      # Disperse throughout project.
      return project.disperse(influence, propagations, id)

    # If at a termination point due to lack of associations:
    elsif digital_objects.count == 0

      # Consume influence and return nothing.
      return {}

    # Normal propagation step, otherwise.
    else

      # Create empty results hash.
      results = {}

      # Determine the amount of influence each.
      amount = influence / digital_objects.count

      # Query each association.
      digital_objects.each do |object|

        # Fetch results from associate.
        response = object.collaborate(amount, propagations - 1, dispersal)

        # Merge response to results.
        aggregate(results, response)

      end

      # Return results.
      return results

    end
  end

  # Check if two or more concepts shall be flattened:
  def check_flatten

    # Find all concepts with the same project id.
    same_project_concepts = Concept.where(
      project_id: project_id
    ).to_a

    # Remove self.
    same_project_concepts.delete(self)

    # Create list of matching concepts.
    same_concepts = []
    target_matchable_description = matchable_description
    same_project_concepts.each do |concept|

      # If a duplicate matchable description, add to list.
      if concept.matchable_description.eql? target_matchable_description
        same_concepts << concept
      end
    end

    #If there are other concepts with the same details:
    if same_concepts.count > 0

      # For each concept:
      same_concepts.each do |same_concept|

        # Flatten that concept into this concept.
        flatten(same_concept)
      end
    end

    # Allow save to continue.
    return true
  end

  # Returns the most matchable description of a concept.
  def matchable_description

    # Lower case, punctuation stripped.
    return description.downcase.gsub(/[^a-z0-9\s]/i, '')

  end

  # Merge with other concepts.
  def merge(*concepts)

    # For each concept to be merged:
    concepts.each do |concept|

      # Append its description as a new paragraph.
      description << "\n\n" << concept.description

      # For each object it is associated with:
      concept.digital_objects.each do |object|

        # Add it, unless it is already associated with this concept.
        unless digital_objects.include? object
          digital_objects << object
        end
      end

      # Destroy the merged concept.
      concept.destroy
    end
  end

  # Private methods.
  private

  # Flatten another concept into this one.
  def flatten(other_concept)

    # Go through the other concepts's objects.
    other_concept.digital_objects.each do |object|

      # Accept each new object.
      unless digital_objects.include? object
        digital_objects << object
      end
    end

    # Adopt existing concept's description.
    self.description = other_concept.description

    # Destroy the other concept.
    other_concept.destroy
  end

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
