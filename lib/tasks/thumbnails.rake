namespace :thumbnails do
  desc "Clears all object thumbnail urls."
  task clear_object_thumbnail_urls: :environment do

    # Reset every object's location.
    DigitalObject.all.each do |object|

      # Clear all thumbnail urls.
      object.update(thumbnail_url: nil)
    end
  end

  desc "Regenerate all thumbnails."
  task regenerate_thumbnails: :environment do

    # Resets all thumbnails.
    Thumbnail.all.each do |thumbnail|

      # Generate thumbnail image.
      thumbnail.generate
    end
  end

end
