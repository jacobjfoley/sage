namespace :thumbnails do
  desc "Resets all object thumbnail urls."
  task reset_thumbnail_urls: :environment do

    # Touch every object's location.
    DigitalObject.all.to_a.map(&:touch(:location))
  end

end
