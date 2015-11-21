namespace :thumbnails do
  desc "Generate all thumbnails."
  task generate_all: :environment do

    # For all thumbnails:
    Thumbnail.all.each do |thumbnail|

      # Generate thumbnail.
      thumbnail.generate
    end
  end

  desc "Check all thumbnails."
  task check: :environment do

    # Schedule a thumbnail check.
    CheckThumbnailsJob.perform_later
  end
end
