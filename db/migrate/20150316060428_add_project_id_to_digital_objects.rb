class AddProjectIdToDigitalObjects < ActiveRecord::Migration
  def change
    add_column :digital_objects, :project_id, :integer
    add_index :digital_objects, :project_id
  end
end
