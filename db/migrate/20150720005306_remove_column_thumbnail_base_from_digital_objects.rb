class RemoveColumnThumbnailBaseFromDigitalObjects < ActiveRecord::Migration
  def change
    remove_column :digital_objects, :thumbnail_base, :string
  end
end
