class Concept < ActiveRecord::Base

  has_many :annotations, dependent: :destroy
  has_many :digital_objects, through: :annotations
  belongs_to :project

  validates :description, presence: true

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

  # Find entities by association.
  def related

    # Return the entities associated with this element.
    return digital_objects.to_a
  end

  # Wrap self in an algorithm.
  def algorithm(specific = nil)

    # Get algorithm name. Check specific, then project, then default to SAGA.
    name = specific || project.algorithm || 'SAGA'

    # Map algorithms to names.
    algorithms = {
      'SAGA' => SAGA::Concept,
      'Baseline' => Baseline::Concept,
      'Vote' => Rank::Vote,
      'VotePlus' => Rank::VotePlus,
      'Sum' => Rank::Sum,
      'SumPlus' => Rank::SumPlus
    }

    # Return object.
    return algorithms[name].new(self)
  end

  # Find relevant objects.
  def relevant

    # Calculate influence to spread.
    influence = project.digital_objects.count.to_f

    # Default influence, three steps (find object).
    results = collaborate(influence, 3)

    # Distribute minimal influence among popular.
    popular = project.popular_objects(results[:popular])
    results.delete :popular

    # Merge collaboration results with popular.
    aggregate(results, popular)

    # Filter weak results.
    filter_results(results)

    # Return sorted results.
    return results.sort_by {|key, value| value}.reverse.to_h
  end

  # Collaborate with other agents to detect relationships within the project.
  def collaborate(influence, propagations)

    # Determine what to do.
    # If at the natural end point:
    if propagations == 0

      # Assign influence to self and return.
      return { self => influence }

    # Normal propagation step, otherwise.
    else

      # Signal all members of the concept cluster.
      consult_cluster(influence, propagations)
    end
  end

  # Signal all concepts within this cluster.
  def consult_cluster(influence, propagations)

    # Find all similar concepts.
    similar = WordTable.text_similarity(id)

    # Determine total weight in results.
    total = 0.0
    similar.values.each do |value|
      total += value
    end

    # Determine portion of influence.
    portion = influence / total

    # Create results hash.
    results = {}

    # For each similar result:
    similar.keys.each do |key|

      # Find concept.
      concept = Concept.find(key)

      # Call each similar concept with their portion of total influence.
      response = concept.disperse(similar[key] * portion, propagations)

      # Assimilate response.
      aggregate(results, response)
    end

    # Return end result.
    return results
  end

  # Disperse influence to objects.
  def disperse(influence, propagations)

    # Determine the amount of influence each.
    amount = influence / (digital_objects.count + 1)

    # Create empty results hash.
    results = { popular: amount }

    # Query each association.
    digital_objects.each do |object|

      # Fetch results from associate.
      response = object.collaborate(amount, propagations - 1)

      # Merge response to results.
      aggregate(results, response)
    end

    # Return results.
    return results
  end

  # Establish a cutoff point in results.
  def filter_results(results)

    # Establish the cutoff value.
    cutoff = 1.0 - results.values.min

    # Filter based on this value.
    results.keys.each do |key|

      # If a result is below the cutoff, remove result.
      if results[key] < cutoff
        results.delete key
      end
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
