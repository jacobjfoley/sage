class AddFilenameToDigitalObjects < ActiveRecord::Migration
  def change
    add_column :digital_objects, :filename, :string
  end
end
