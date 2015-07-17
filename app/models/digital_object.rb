class DigitalObject < ActiveRecord::Base

  # Associations with other models.
  has_and_belongs_to_many :concepts
  belongs_to :project

  # Validations.
  validates :location, presence: true

  # Callbacks.
  after_create :generate_common_thumbnails
  before_save :check_convertible_location, if: :location_changed?
  before_save :check_flatten, if: :location_changed?

  # Returns ranked ordering of objects by association count.
  def self.ranked(project_id)

    # Get objects.
    digital_objects = DigitalObject.where(project: project_id)

    # Sort by association count.
    digital_objects.to_a.sort! {
      |a,b| a.concepts.count <=> b.concepts.count
    }

    # Return list.
    return digital_objects
  end

  # Find relevant objects.
  def relevant

    # Calculate influence to spread.
    influence = project.concepts.count.to_f

    # Default influence, three steps (find concept), hasn't dispersed yet.
    results = collaborate(influence, 3, false)

    # Distribute minimal influence among popular.
    popular = project.popular_concepts(1.0)

    # Merge collaboration results with popular.
    aggregate(results, popular)

    # Return filtered, sorted results.
    return results.sort_by {|key, value| value}.reverse.to_h
  end

  # Collaborate with other agents to detect relationships within the project.
  def collaborate(influence, propagations, dispersal)

    # Determine what to do.
    # If at the natural end point:
    if propagations == 0

      # Assign influence to self and return.
      return {self => influence}

    # If at a termination point due to lack of associations:
    elsif concepts.count == 0

      # Consume influence and return nothing.
      return {}

    # Normal propagation step, otherwise.
    else

      # Create empty results hash.
      results = {}

      # Determine the amount of influence each.
      amount = influence / concepts.count

      # Query each association.
      concepts.each do |concept|

        # Fetch results from associate.
        response = concept.collaborate(amount, propagations - 1, dispersal)

        # Merge response to results.
        aggregate(results, response)

      end

      # Return results.
      return results

    end
  end

  # Get a thumbnail for the specified size and object.
  def thumbnail(x, y)

    # Retrieve a thumbnail for this object.
    Thumbnail.find_for(location, x, y)
  end

  # Attempts to repair thumbnails.
  def repair_thumbnails()

    # Fetch all thumbnails sharing the broken source.
    thumbnails = Thumbnail.where(source: location)

    # Generate new thumbnail images for each.
    thumbnails.each do |thumbnail|

      # Generate thumbnail image.
      thumbnail.generate
    end
  end

  # Check if the object's location is likely to be a link.
  def has_uri?

    # Compare location with a valid URI's regexp.
    return location =~ /\A#{URI::regexp}\z/
  end

  # Private methods.
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

  # Check if the location should be converted.
  def check_convertible_location

    # Define locations with ID captures.
    google_location = %r{\Ahttps://drive.google.com/open\?id=(?<file_id>\w+)\z}

    # Check Google locations.
    if (data = google_location.match location)
      self.location = "https://www.googleapis.com/drive/v2/files/#{data[:file_id]}"
    end

    # Allow save to continue.
    return true
  end

  # Check if two or more objects shall be flattened:
  def check_flatten

    # Find all digital objects with the same project id and location.
    same_objects = DigitalObject.where(
      project_id: project_id,
      location: location
    )

    # Remove self.
    same_objects.delete(self)

    # If other objects have the same attributes:
    if same_objects.count > 0

      # For each object:
      same_objects.each do |same_object|

        # Flatten that object into this object.
        flatten(same_object)
      end
    end
  end

  # Flatten another digital object into this one.
  def flatten(other_object)

    # Go through the other object's concepts.
    other_object.concepts.each do |concept|

      # Accept each new concept.
      unless concepts.include? concept
        concepts << concept
      end
    end

    # Accept other object's thumbnail base (e.g. if a custom thumbnail base).
    thumbnail_base = other_object.thumbnail_base

    # Destroy the flattened object.
    other_object.destroy
  end

  # Generate the common thumbnail sizes.
  def generate_common_thumbnails

    # Generate the two standard sizes of images.
    thumbnail(150,150)
    thumbnail(400,400)
  end
end
