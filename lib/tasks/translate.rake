namespace :translate do
  desc "Update Google Drive hosted content with web content links."
  task host_to_wcl: :environment do

    # Fetch all digital objects.
    DigitalObject.all.each do |object|

      # Form appropriate regular expression.
      google_regexp = %r{https://.*googledrive.com/host/(.*)}

      # Determine if a googledrive link.
      if google_regexp.match(object.location)

        # New location.
        wcl = "https://docs.google.com/uc?id="

        # Extract the file id.
        id = google_regexp.match(object.location)[1]

        # Update new location using WebContentLink.

      end
    end
  end
end
