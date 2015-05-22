require 'digest'
require 'fileutils'
require 'open-uri'

class DigitalObject < ActiveRecord::Base

  # Associations with other models.
  has_and_belongs_to_many :concepts
  belongs_to :project

  # Validations.
  validates :location, presence: true

  # Callbacks.
  before_save :prepare_link, if: :location_changed?
  before_save :clear_thumbnails, if: :location_changed?
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

    # Calculate the digest of the object's original URL.
    digest = Digest::SHA256.hexdigest location

    # Check if the thumbnail of the image and specified size exists.
    if File.exist? "public/thumbnails/#{digest}_#{x}x#{y}.jpg"

      # Return the URL to the caller.
      return "/thumbnails/#{digest}_#{x}x#{y}.jpg"

    else

      # Schedule to create it.
      #GenerateThumbnailJob.perform_later(self, x, y, digest)
      generate_thumbnail(x, y, digest)

      # Return placeholder URL.
      return "/hourglass.jpg"
    end
  end

  # Generate a new thumbnail.
  def generate_thumbnail(x, y, digest)

    # Fetch a representation of the resource.
    begin

      # Fetch resource.
      open("tmp/#{digest}", "wb").write(open(location).read)

      # Attempt to read resource as though it were an image.
      image = Magick::Image.read("tmp/#{digest}").first

    # In the event of the resource not being an image:
    rescue Magick::ImageMagickError, OpenURI::HTTPError

      # Get a generic image as a substitute.
      image = Magick::Image.read("app/assets/images/generic_file.jpg").first

    end

    # If the image is larger than the desired size:
    #if (image.x_resolution > x || image.y_resolution > y)

      # Resize image to the desired size.
      image = image.resize_to_fit(x, y)
    #end

    # Write the new thumbnail to the thumbnail cache.
    image.write "public/thumbnails/#{digest}_#{x}x#{y}.jpg"
  end

  # Clear existing thumbnails.
  def clear_thumbnails()

    # Calculate the digest of the object's original URL.
    digest = Digest::SHA256.hexdigest location

    # Get all thumbnails belonging to this object.
    thumbnails = Dir.glob("public/thumbnails/#{digest}_*")

    # Delete each thumbnail.
    thumbnails.each do |thumbnail|
      File.delete thumbnail
    end
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
