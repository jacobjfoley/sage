class Concept < ActiveRecord::Base

  has_many :annotations, dependent: :destroy
  has_many :digital_objects, through: :annotations
  belongs_to :project

  validates :description, presence: true

  before_save :check_flatten, if: :description_changed?

  # Map algorithms to names.
  ALGORITHMS = {
    '' => SAGA::Concept,
    'SAGA' => SAGA::Concept,
    'SAGA-Refined' => SAGA::Concept_Refined,
    'Shuffle' => Shuffle::Concept,
    'Annotated' => Annotated::Concept,
    'None' => None::Concept,
    'All' => All::Concept,
    'Vote' => Rank::Vote,
    'VotePlus' => Rank::VotePlus,
    'Sum' => Rank::Sum,
    'SumPlus' => Rank::SumPlus
  }

  # Find a concept that matches the provided details hash, or create a new one.
  def self.match_or_create(details)

    # Create a new concept using details.
    candidate = Concept.new(details)

    # See if there are any matching concepts.
    matching_concepts = candidate.matching

    # Check if matching or unique.
    if matching_concepts.empty?

      # Preserve candidate.
      candidate.save
    else

      # Swap out for matching concept instead.
      candidate = matching_concepts.first
    end

    # Return new/existing candidate.
    return candidate
  end

  # Find all matching concepts.
  def matching

    # Find all concepts with the same project id.
    concepts = Concept.where(project: project).to_a

    # Remove self.
    concepts.delete(self)

    # Specify the target description to be matched.
    target = matchable_description

    # Create list of matching concepts.
    matching_concepts = []
    concepts.each do |concept|

      # If a duplicate matchable description, add to list.
      if concept.matchable_description.eql? target
        matching_concepts << concept
      end
    end

    # Return list.
    return matching_concepts
  end

  # Find entities by annotation.
  def related

    # Return the entities associated with this element.
    return digital_objects.to_a
  end

  # Wrap self in an algorithm.
  def algorithm(specific = nil)

    # Get algorithm name. Check specific for overrides, then project.
    name = specific || project.algorithm

    # If a valid algorithm name wasn't provided, use default.
    if !ALGORITHMS.key? name
      name = ""
    end

    # Return object.
    return ALGORITHMS[name].new(self)
  end

  # Check if valid algorithm has been provided.
  def valid_algorithm?(algorithm = project.algorithm)

    # True if blank or registered algorithm.
    return (!algorithm || (ALGORITHMS.key? algorithm))
  end

  # Check if two or more concepts shall be flattened:
  def check_flatten

    # Find all matching concepts.
    matching_concepts = matching

    #If there are other concepts with the same details:
    if matching_concepts.count > 0

      # For each concept:
      matching_concepts.each do |concept|

        # Flatten that concept into this concept.
        flatten(concept)
      end
    end

    # Allow save to continue.
    return true
  end

  # Returns the most matchable description of a concept.
  def matchable_description

    # Get description.
    processing = String.new(description)

    # Downcase.
    processing.downcase!

    # Strip all non-alphanumeric characters.
    processing.gsub!(/[^a-z0-9\s]/, '')

    # Strip excess whitespace.
    processing.gsub!(/\s+/, ' ')

    # Chomp trailing whitespace.
    processing.chomp!(" ")

    # Lower case, punctuation stripped.
    return processing
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

    # Go through the other concepts's annotations.
    Annotation.where(concept: other_concept).each do |prospective|

      # Check if already annotated.
      unless digital_objects.include? prospective.digital_object

        # Modify annotation.
        prospective.update(concept_id: id)
      end
    end

    # Adopt existing concept's description.
    self.description = other_concept.description

    # Destroy the other concept.
    other_concept.destroy
  end
end
