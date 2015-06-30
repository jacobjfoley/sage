class ChangeThumbnailBaseJob < ActiveJob::Base
  queue_as :default

  # Generate an appropriate thumbnail base for an object.
  def perform(object_id, thumbnail_location)

    # If the digital object exists:
    if DigitalObject.exists?(object_id)
      
      # Load object.
      object = DigitalObject.find(object_id)

      # If the thumbnail base still hasn't been generated yet:
      if object.thumbnail_base.nil?

        # Generate a thumbnail base.
        object.generate_thumbnail_base(thumbnail_location)
      end
    end
  end
end
