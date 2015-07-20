namespace :thumbnails do
  desc "Resets all object thumbnail urls."
  task reset_thumbnail_urls: :environment do

    # Reset every object's location.
    DigitalObject.all.each do |object|

      # Clear all thumbnail urls.
      object.update(thumbnail_url: nil)
    end
  end

end
