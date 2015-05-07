class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.text :notes
      t.string :administrator_key
      t.string :contributor_key
      t.string :viewer_key

      t.timestamps
    end
  end
end
