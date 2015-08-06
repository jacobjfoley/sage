class AddAnnotatorKeyToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :annotator_key, :string
  end
end
