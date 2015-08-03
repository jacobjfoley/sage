class DigitalObject < ActiveRecord::Base

  has_many :annotations, dependent: :destroy
  has_many :concepts, through: :annotations
  belongs_to :project

  validates :location, presence: true

  before_save :check_conversions, if: :location_changed?
  before_save :reset_thumbnail_url, if: :location_changed?
  before_save :check_flatten, if: :location_changed?
  after_create :create_thumbnails

  # Find entities by annotation.
  def related

    # Return the entities associated with this element.
    return concepts.to_a
  end

  # Wrap self in an algorithm.
  def algorithm(specific = nil)

    # Get algorithm name. Check specific, then project, then default to SAGA.
    name = specific || project.algorithm || 'SAGA'

    # Map algorithms to names.
    algorithms = {
      'SAGA' => SAGA::Object,
      'Baseline' => Baseline::Object,
      'Vote' => Rank::Vote,
      'VotePlus' => Rank::VotePlus,
      'Sum' => Rank::Sum,
      'SumPlus' => Rank::SumPlus
    }

    # Return object.
    return algorithms[name].new(self)
  end

  # Get a thumbnail for the specified size and object.
  def thumbnail(x, y)

    # If the thumbnail hasn't been set for this object:
    if thumbnail_url == nil

      # Generate thumbnail url.
      generate_thumbnail_url
    end

    # Retrieve a thumbnail for this object.
    Thumbnail.find_for(thumbnail_url, x, y)
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

  # Checks if a given location should be changed before saving, particularly
  # when using other services as content providers.
  def check_conversions

    # Check Google Drive conversions.
    check_google_drive_conversion

    # Allow save to continue.
    return true
  end

  # Check if two or more objects shall be flattened:
  def check_flatten

    # Find all digital objects with the same project id and location.
    same_objects = DigitalObject.where(
      project_id: project_id,
      location: location
    ).to_a

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

  # Check if the location should be converted.
  def check_google_drive_conversion

    # Define locations with ID captures.
    drive_location = %r{\Ahttps://drive.google.com/open\?id=(?<file_id>\w+)\z}

    # Check Google locations.
    if (data = drive_location.match location)
      self.location = "https://docs.google.com/uc?id=#{data[:file_id]}"
    end
  end

  # Check if the location is a WebContentLink and set thumbnail_url accordingly.
  def check_google_wcl_thumbnail

    # Define locations with ID captures.
    wcl_location = %r{\Ahttps://docs.google.com/uc\?id=(?<file_id>\w+)\z}

    # Check Google locations.
    if (data = wcl_location.match location)
      self.thumbnail_url = "https://www.googleapis.com/drive/v2/files/#{data[:file_id]}"
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
    thumbnail_url = other_object.thumbnail_url

    # Destroy the flattened object.
    other_object.destroy
  end

  # Generates this object's thumbnail URL.
  def generate_thumbnail_url

    # Initialise to default.
    self.thumbnail_url = location

    # Check if a Google WebContentLink.
    check_google_wcl_thumbnail

    # Commit changes.
    self.save
  end

  # Resets the thumbnail url every time the location changes.
  def reset_thumbnail_url

    # Set thumbnail url to nil.
    self.thumbnail_url = nil

    # Allow save to continue.
    return true
  end

  # Schedule for common thumbnail sizes to be created.
  def create_thumbnails

    # Create the two common thumbnail sizes.
    delay.thumbnail(150,150)
    delay.thumbnail(400,400)
  end
end
