class AddFilenameToThumbnails < ActiveRecord::Migration
  def change
    add_column :thumbnails, :filename, :string
  end
end
