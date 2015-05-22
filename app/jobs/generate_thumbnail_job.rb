class GenerateThumbnailJob < ActiveJob::Base
  queue_as :default

  # Generate a thumbnail for the given object.
  def perform(object, x, y, digest)

    # If the thumbnail still hasn't been generated yet:
    #unless File.exist? "public/thumbnails/#{digest}_#{x}x#{y}.jpg"

      # Generate a thumbnail.
      object.generate_thumbnail(x, y, digest)
    #end
  end
end
