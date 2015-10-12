class Concept < ActiveRecord::Base

  has_many :annotations, dependent: :destroy
  has_many :digital_objects, through: :annotations
  belongs_to :project

  validates :description, presence: true

  before_save :check_flatten, if: :description_changed?

  # Find entities by annotation.
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
      'SAGA-Refined' => SAGA::Concept_Refined,
      'Baseline' => Baseline::Concept,
      'Vote' => Rank::Vote,
      'VotePlus' => Rank::VotePlus,
      'Sum' => Rank::Sum,
      'SumPlus' => Rank::SumPlus
    }

    # Return object.
    return algorithms[name].new(self)
  end

  # Check if two or more concepts shall be flattened:
  def check_flatten

    # Find all concepts with the same project id.
    same_project_concepts = project.concepts.to_a

    # Remove self.
    same_project_concepts.delete(self)

    # Specify the target description to be matched.
    target_matchable_description = matchable_description

    # Create list of matching concepts.
    same_concepts = []
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
    return description.downcase.chomp.gsub(/[^a-z0-9\s]/i, '')
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
