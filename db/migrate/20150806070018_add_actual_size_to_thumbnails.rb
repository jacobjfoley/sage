class AddActualSizeToThumbnails < ActiveRecord::Migration
  def change
    add_column :thumbnails, :actual_x, :integer
    add_column :thumbnails, :actual_y, :integer
  end
end
