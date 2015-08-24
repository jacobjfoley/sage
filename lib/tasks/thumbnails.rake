namespace :thumbnails do
  desc "Clears all object thumbnail urls."
  task clear_object_thumbnail_urls: :environment do

    # Reset every object's location.
    DigitalObject.all.each do |object|

      # Clear all thumbnail urls.
      object.update(thumbnail_url: nil)
    end
  end

  desc "Generate all thumbnails."
  task generate_all: :environment do

    # For all thumbnails:
    Thumbnail.all.each do |thumbnail|

      # Generate thumbnail.
      thumbnail.generate
    end
  end

  desc "Set all object filenames."
  task set_filenames: :environment do

    # For all thumbnails:
    DigitalObject.all.each do |object|

      # Set filename.
      object.delay.set_filename
    end
  end

  desc "Carry over all object filenames."
  task convert_filenames: :environment do

    # For all thumbnails:
    DigitalObject.all.each do |object|

      # Set filename.
      object.update(filename: object.thumbnail(150,150).filename)
    end
  end
end
