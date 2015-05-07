module RenderHelper
  def render_resource(uri, *options)
    
    # Define renderable resources.
    images = %w(.png .jpg .jpeg .gif .bmp)
    
    # Check if uri matches a renderable resource. 
    # If so, render it. Otherwise, render a placeholder. 
    if images.include? File.extname(uri).downcase
      image_tag uri, *options
    else
      image_tag "generic_file.png", *options
    end
  end
end
