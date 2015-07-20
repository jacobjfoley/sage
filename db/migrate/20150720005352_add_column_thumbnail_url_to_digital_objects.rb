class AddColumnThumbnailUrlToDigitalObjects < ActiveRecord::Migration
  def change
    add_column :digital_objects, :thumbnail_url, :string
  end
end
