class DigitalObject < ActiveRecord::Base

  # Associations with other models.
  has_and_belongs_to_many :concepts
  belongs_to :project

  # Validations.
  validates :location, presence: true

  # Callbacks.
  before_save :prepare_link, if: :location_changed?
  before_save :change_thumbnail_base, if: :location_changed?
  before_destroy :clear_thumbnails

  # Find relevant objects.
  def relevant

    # Calculate influence to spread.
    influence = project.concepts.count

    # Default influence, three steps (find concept), hasn't dispersed yet.
    results = collaborate(influence, 3, false)

    # Calculate absorbed influence.
    absorbed = 0.0
    concepts.each do |concept|
      absorbed += results[concept]
    end

    # Calculate missing influence.
    missing = influence
    results.keys.each do |key|
      missing -= results[key]
    end

    # Distribute consumed and absorbed influence among popular.
    popular = project.popular_concepts(absorbed+missing)

    # Merge harmonic intuition results with popular.
    aggregate(results, popular)

    # # Filter weak results.
    # results.keys.each do |key|
    #   if results[key] < 1.0
    #     results.delete key
    #   end
    # end

    # Return filtered results.
    return results
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

  # Get the URL of the digital object's thumbnail.
  def thumbnail(x, y)

    # Check if thumbnail base hasn't been defined.
    if thumbnail_base.nil?

      # Generate a thumbnail base and possibly thumbnail.
      GenerateThumbnailAndBaseJob.perform_later(id, x, y)

      # Return placeholder URL.
      return "/processing.svg"

    # Check if scalable image.
    elsif thumbnail_base =~ /\.svg\z/

      # SVGs will automatically resize.
      return thumbnail_base

    # Otherwise, processed thumbnail is required.
    else

      # Calculate the digest of the object's thumbnail base.
      digest = Digest::SHA256.hexdigest thumbnail_base

      # Determine potential location on Amazon S3.
      object = Aws::S3::Object.new("sage-une", "#{digest}_#{x}x#{y}.jpg")

      # Check if suitable thumbnail is already in cache.
      if object.exists?

        # Return the URL to the caller.
        return "https://s3-ap-southeast-2.amazonaws.com/sage-une/#{digest}_#{x}x#{y}.jpg"

      # Otherwise, new thumbnail needed.
      else

        # Schedule a new thumbnail generation job.
        GenerateThumbnailJob.perform_later(id, x, y, digest)

        # Return placeholder URL.
        return "/processing.svg"
      end
    end
  end

  # Generate a new thumbnail.
  def generate_thumbnail(x, y, digest)

    # Fetch a representation of the resource.
    begin

      # Specify resource.
      resource = RestClient::Resource.new(thumbnail_base)

      # Attempt to read resource.
      image = Magick::Image.from_blob(resource.get).first

      # If the image is larger than the desired size:
      if (image.x_resolution > x || image.y_resolution > y)

        # Resize image to the desired size.
        image = image.resize_to_fit(x, y)
      end

      # Access Amazon S3 object.
      object = Aws::S3::Object.new("sage-une", "#{digest}_#{x}x#{y}.jpg")

      # Write thumbnail to S3.
      object.put({acl: "public-read", body: image.to_blob})

    # Rescue in the event of an error.
    rescue Magick::ImageMagickError

      # Use a bug thumbnail.
      self.thumbnail_base = "/bug.svg"

      # Save changes.
      self.save
    end
  end

  # Sets the thumbnail base appropriately for the object's location.
  def generate_thumbnail_base(location)

    # If the location is not a URI:
    if location !~ /\A#{URI::regexp}\z/

      self.thumbnail_base = "/text.svg"

    # The location is a URI.
    else

      # Fetch the resource's metadata.
      response = RestClient.head(location)

      # Check if a broken URI.
      if response.code != 200

        # Use a missing file thumbnail.
        self.thumbnail_base = "/missing.svg"

      # Check if an image file.
      elsif response.headers[:content_type] =~ /\Aimage/

        # The location is an image file. Use it for the thumbnail.
        self.thumbnail_base = location

      # Otherwise, unknown filetype.
      else

        # Use a generic file thumbnail.
        self.thumbnail_base ="/generic.svg"
      end
    end

    # Save changes.
    self.save
  end

  # Change thumbnail base.
  def change_thumbnail_base(thumbnail_location = location)

    # Clear existing thumbnails.
    unless thumbnail_base.nil?
      clear_thumbnails()
    end

    # Remove thumbnail base.
    self.thumbnail_base = nil

    # Queue thumbnail job.
    ChangeThumbnailBaseJob.perform_later(id, thumbnail_location)
  end

  # Clear existing thumbnails.
  def clear_thumbnails()

    # Calculate the digest of the object's original URL.
    digest = Digest::SHA256.hexdigest thumbnail_base

    # Create S3 bucket resource.
    bucket = Aws::S3::Bucket.new("sage-une")

    # Get all thumbnails belonging to this object.
    thumbnails = bucket.objects({prefix: digest})

    # Extract into array.
    delete_array = []
    thumbnails.each do |thumbnail|
      delete_array << {key: thumbnail.key}
    end

    # Delete each thumbnail.
    bucket.delete_objects({delete: {objects: delete_array}})
  end

  # Identifies if the provided location is a google link, and if so, prepares
  # a webcontentlink to the same resource instead. This is accessible to both
  # users and the server and preserves the object's id.
  def prepare_link

    # Form appropriate regular expression.
    google_regexp = %r{https://drive\.google\.com/open\?(.*)}

    # Determine if a googledrive link.
    if google_regexp.match(location)

      # New location.
      wcl = "https://docs.google.com/uc?"

      # Extract the file id.
      id = google_regexp.match(location)[1]

      # Update new location using WebContentLink.
      self.location = wcl + id
    end
  end

  # Identify if the object's location can be used as a valid URI.
  def has_uri?

    # Check if location matches URI regexp.
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
end
