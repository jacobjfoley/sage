module ThumbnailHelper

  # Gets an appropriate URL from a thumbnail.
  def thumbnail_url(thumbnail)

    # If the thumbnail doesn't have an URL yet:
    if thumbnail.url.nil?

      # Return the processing thumbnail.
      return asset_path(Thumbnail::PROCESSING_THUMBNAIL)

    # If the thumbnail's URL is a local file:
    elsif thumbnail.local

      # Return the named local asset.
      return asset_path(thumbnail.url)

    # Otherwise, thumbnail's URL is external.
    else

      # Return URL as-is.
      return thumbnail.url
    end
  end
end
