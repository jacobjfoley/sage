class AddProjectIdToConcepts < ActiveRecord::Migration
  def change
    add_column :concepts, :project_id, :integer
    add_index :concepts, :project_id
  end
end
