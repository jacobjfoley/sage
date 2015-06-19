class GenerateThumbnailJob < ActiveJob::Base
  queue_as :default

  # Generate a thumbnail for the given object.
  def perform(object_id, x, y, digest)

    # Load object.
    object = DigitalObject.find(object_id)

    # If the thumbnail hasn't already been generated:
    unless File.exist? "public/thumbnails/#{digest}_#{x}x#{y}.jpg"

      # Generate a thumbnail.
      object.generate_thumbnail(x, y, digest)
    end
  end
end
