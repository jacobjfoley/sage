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

  URI_REGEXP = %r{\A#{URI::regexp}\z}
  GOOGLE_REGEXP = %r{\Ahttps://www.googleapis.com/drive/v2/files/}

  # Retrieve a thumbnail for a given resource.
  def self.find_for(source, x, y)

    # Retrieve thumbnail, if thumbnail exists.
    thumbnail = Thumbnail.find_or_create_by(source: source, x: x, y: y)

    # If the thumbnail doesn't have a thumbnail image:
    if thumbnail.url.nil?

      # Create a thumbnail.
      thumbnail.generate
    else

      # Check thumbnail later.
      thumbnail.delay.check_thumbnail
    end

    # Return the thumbnail.
    return thumbnail
  end

  # Generates a thumbnail's URL.
  def generate

    # Clear any current URL and details.
    update(
      url: nil,
      actual_x: 0,
      actual_y: 0
    )

    # Generate the thumbnail image.
    SetThumbnailURLJob.perform_later(id)
  end

  # Check that the thumbnail image still exists.
  def check_thumbnail

    # Unless a local file or not a URI:
    unless local || (url !~ URI_REGEXP)

      # Begin attempt.
      begin

        # Fetch the resource's metadata.
        response = RestClient.head(url)

      # Rescue on exception.
      rescue RestClient::ResourceNotFound

        # Re-generate thumbnail.
        generate
      end
    end
  end

  # Detect if the image is in portrait orientation.
  def portrait?

    # Determine if the image is taller than wide.
    return actual_x < actual_y
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

        # Check if Google resource.
        if source =~ GOOGLE_REGEXP

          # Fetch the resource's metadata using key.
          response = RestClient.head source, {params: {key: ENV["GOOGLE_API_KEY"], alt: "media"}}

        # Otherwise, does not need an access key.
        else

          # Fetch the resource's metadata.
          response = RestClient.head(source)
        end

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
  private

  # Create a new thumbnail for an image.
  def create_image_thumbnail

    # Create the thumbnail image.
    begin

      # Check if Google resource.
      if source =~ GOOGLE_REGEXP

        # Fetch blob using key.
        blob = RestClient.get source, {params: {key: ENV["GOOGLE_API_KEY"], alt: "media"}}

      # Otherwise, does not need an access key.
      else

        # Fetch blob.
        blob = RestClient.get source
      end

      # Attempt to read resource.
      image = Magick::Image.from_blob(blob).first

      # If the image is larger than the desired size:
      if (image.columns > x) || (image.rows > y)

        # Resize image to the desired size.
        image = image.resize_to_fit(x, y)
      end

      # Access Amazon S3 object.
      object = Aws::S3::Object.new(ENV['S3_BUCKET'], "#{digest}_#{x}x#{y}.jpg")

      # Write thumbnail to S3.
      object.put({acl: "public-read", body: image.to_blob})

      # Store URL and actual sizes in thumbnail.
      update(
        url: "https://s3-ap-southeast-2.amazonaws.com/#{ENV['S3_BUCKET']}/#{digest}_#{x}x#{y}.jpg",
        actual_x: image.columns,
        actual_y: image.rows
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
