namespace :thumbnails do
desc "Generate all thumbnails."
  task generate_all: :environment do

    # For all thumbnails:
    Thumbnail.all.each do |thumbnail|

      # Generate thumbnail.
      thumbnail.generate
    end
  end
end
