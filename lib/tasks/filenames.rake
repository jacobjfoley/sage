namespace :filenames do
  desc "Generate all filenames."
  task generate_all: :environment do

    # For all objects:
    DigitalObject.all.each do |object|

      # Generate thumbnail.
      object.delay.set_filename
    end
  end
end
