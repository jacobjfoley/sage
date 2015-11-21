class CheckThumbnailsJob < ActiveJob::Base
  queue_as :default

  def perform

    # Perform checks.
    expire_thumbnails
    expand_thumbnails
  end

  # Remove old thumbnails.
  def expire_thumbnails

    # Find the effective expiry age.
    expiry_age = Thumbnail::EXPIRY - Thumbnail::EXPIRY_CHECK_INTERVAL

    # For all thumbnails, destroy if expiring:
    Thumbnail.all.each do |t|

      # Check if thumbnail's age is at the expiry age.
      if (Time.now - t.created_at) >= expiry_age

        # Expire thumbnail.
        t.destroy
      end
    end
  end

  # Ensure comprehensive thumbnails are available for all objects.
  def expand_thumbnails

    # Find all thumbnail urls referenced by digital objects.
    used_thumbnails = DigitalObject.all.map{ |o| o.thumbnail_url }

    # Restrict to unique thumbnails.
    used_thumbnails.uniq!

    # For each common size:
    Thumbnail::COMMON_SIZES.each do |size|

      # Get all existing thumbnail sources of this size.
      existing_thumbnails = Thumbnail.where(x: size, y: size).map {|t|
        t.source
      }

      # Determine needed thumbnails.
      needed_thumbnails = used_thumbnails - existing_thumbnails

      # For each needed thumbnail:
      needed_thumbnails.each do |url|

        # Make request.
        Thumbnail.find_for(url, size, size)
      end
    end
  end
end
