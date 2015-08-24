class RemoveFilenameFromThumbnails < ActiveRecord::Migration
  def change
    remove_column :thumbnails, :filename, :string
  end
end
