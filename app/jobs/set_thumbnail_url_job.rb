class SetThumbnailURLJob < ActiveJob::Base
  queue_as :default

  def perform(thumbnail_id)

    # If the thumbnail exists:
    if Thumbnail.exists?(thumbnail_id)

      # Get the thumbnail object.
      thumbnail = Thumbnail.find(thumbnail_id)

      # If the thumbnail doesn't already have an URL:
      if thumbnail.url.nil?

        # Set the thumbnail's URL.
        thumbnail.set_url
      end

      # If the thumbnail doesn't already have a filename:
      if thumbnail.filename.nil?

        # Set the thumbnail's filename.
        thumbnail.set_filename
      end
    end
  end
end
