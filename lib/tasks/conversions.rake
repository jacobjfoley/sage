namespace :conversions do

  desc "Converts old API object locations to new WebContentLink locations."
  task api_to_wcl: :environment do

    # Check every single object in this database.
    DigitalObject.all.each do |object|

      # Define locations with File ID capture.
      api_location = %r{\Ahttps://www.googleapis.com/drive/v2/files/(?<file_id>\w+)\z}

      # If the object's location matches the old API locations:
      if (data = api_location.match object.location)

        # Convert to newer-style WCL location.
        object.update(location: "https://docs.google.com/uc?id=#{data[:file_id]}")
      end
    end
  end

end
