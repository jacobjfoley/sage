class AddAlgorithmToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :algorithm, :string
  end
end
