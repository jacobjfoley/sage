class GenerateThumbnailJob < ActiveJob::Base
  queue_as :default

  # Generate a thumbnail for the given object.
  def perform(object_id, x, y, digest)

    # Load object.
    object = DigitalObject.find(object_id)

    # Access Amazon S3 object.
    s3_object = Aws::S3::Object.new("sage-une", "#{digest}_#{x}x#{y}.jpg")

    # If the thumbnail hasn't already been generated:
    unless s3_object.exists?

      # Generate a thumbnail.
      object.generate_thumbnail(x, y, digest)
    end
  end
end
