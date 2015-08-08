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

  # Determine class based on thumbnail orientation.
  def thumbnail_class(thumbnail, gallery)

    # Return a style based on orientation.
    if thumbnail.portrait?
      if gallery
        return "portrait_thumbnail"
      else
        return "landscape_thumbnail"
      end
    else
      return "landscape_thumbnail"
    end
  end

  # Determine style based on thumbnail sizes.
  def thumbnail_style(thumbnail)

    # Check to see if this has a thumbnail URL.
    if thumbnail.url && !thumbnail.local
      return "max-width: #{thumbnail.actual_x}px; max-height: #{thumbnail.actual_y}px"
    else
      return "max-width: #{thumbnail.x}px; max-height: #{thumbnail.y}px"
    end
  end
end
