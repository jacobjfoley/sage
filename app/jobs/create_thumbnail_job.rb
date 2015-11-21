class CreateThumbnailJob < ActiveJob::Base
  queue_as :default

  def perform(thumbnail_id)

    # If the thumbnail exists:
    if Thumbnail.exists?(thumbnail_id)

      # Get the thumbnail object.
      thumbnail = Thumbnail.find(thumbnail_id)

      # If the thumbnail doesn't already have an URL:
      if thumbnail.url.nil?

        # Set the thumbnail's URL.
        thumbnail.create_thumbnail
      end
    end
  end
end
