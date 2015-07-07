class Thumbnail < ActiveRecord::Base

  # Validations.
  validates :source, presence: true
  validates :x, presence: true
  validates :y, presence: true

  # Callbacks.
  before_save :set_local, if: :url_changed?

  # Constants.
  PROCESSING_THUMBNAIL = "processing.svg"
  GENERIC_THUMBNAIL = "generic.svg"
  TEXT_THUMBNAIL = "text.svg"
  ERROR_THUMBNAIL = "bug.svg"
  MISSING_THUMBNAIL = "missing.svg"
  URI_REGEXP = /\A#{URI::regexp}\z/

  # Retrieve a thumbnail for a given resource.
  def self.find_for(source, x, y)

    # Retrieve thumbnail, if thumbnail exists.
    thumbnail = Thumbnail.find_or_create_by(source: source, x: x, y: y)

    # If the thumbnail doesn't have a thumbnail image:
    if thumbnail.url.nil?

      # Create a thumbnail.
      thumbnail.generate
    end

    # Return the thumbnail.
    return thumbnail
  end

  # Generates a thumbnail's URL.
  def generate

    # Clear any current URL.
    update(url: nil)

    # Generate the thumbnail image.
    SetThumbnailURLJob.perform_later(id)
  end

  # Sets a thumbnail url for this thumbnail object.
  def set_url

    # If the source is not a URI:
    if source !~ URI_REGEXP

      # Thumbnail refers to plain text.
      update(url: TEXT_THUMBNAIL)

    # The source is a URI.
    else

      # Attempt to fetch resource data.
      begin

        # Fetch the resource's metadata.
        response = RestClient.head(source)

        # Check if an image file.
        if response.headers[:content_type] =~ /\Aimage/

          # The location is an image file. Use it for the thumbnail.
          create_image_thumbnail()

        # Otherwise, unknown filetype.
        else

          # Use a generic file thumbnail.
          update(url: GENERIC_THUMBNAIL)
        end

      # Rescue in the event of an error.
      rescue RestClient::Exception

        # Use a missing file thumbnail.
        update(url: MISSING_THUMBNAIL)
      end
    end
  end

  # Private methods.
  #private

  # Create a new thumbnail for an image.
  def create_image_thumbnail

    # Create the thumbnail image.
    begin

      # Specify resource.
      resource = RestClient::Resource.new(source)

      # Attempt to read resource.
      image = Magick::Image.from_blob(resource.get).first

      # If the image is larger than the desired size:
      if (image.columns > x) || (image.rows > y)

        # Resize image to the desired size.
        image = image.resize_to_fit(x, y)
      end

      # Access Amazon S3 object.
      object = Aws::S3::Object.new("sage-une", "#{digest}_#{x}x#{y}.jpg")

      # Write thumbnail to S3.
      object.put({acl: "public-read", body: image.to_blob})

      # Store URL in thumbnail.
      update(
        url: "https://s3-ap-southeast-2.amazonaws.com/sage-une/#{digest}_#{x}x#{y}.jpg"
      )

    # Rescue in the event of an error.
    rescue Magick::ImageMagickError

      # Use a bug thumbnail.
      update(url: ERROR_THUMBNAIL)
    end
  end

  # Gets the digest of the thumbnail's source.
  def digest

    # Return the digest.
    return Digest::SHA256.hexdigest source
  end

  # Sets whether the thumbnail uses a local url.
  def set_local

    # Local files are referenced by constants.
    local_files = [
      PROCESSING_THUMBNAIL,
      GENERIC_THUMBNAIL,
      TEXT_THUMBNAIL,
      ERROR_THUMBNAIL,
      MISSING_THUMBNAIL
    ]

    # Determine if the file referenced by url is a local file.
    self.local = local_files.include? url

    # Allow transaction to continue.
    return true
  end
end
