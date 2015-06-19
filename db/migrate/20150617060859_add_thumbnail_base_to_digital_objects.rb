class AddThumbnailBaseToDigitalObjects < ActiveRecord::Migration
  def change
    add_column :digital_objects, :thumbnail_base, :string
  end
end
