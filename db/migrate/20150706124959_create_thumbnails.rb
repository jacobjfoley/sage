class CreateThumbnails < ActiveRecord::Migration
  def change
    create_table :thumbnails do |t|
      t.string :source
      t.integer :x
      t.integer :y
      t.string :url
      t.boolean :flipped
      t.boolean :local

      t.timestamps null: false
    end

    add_index :thumbnails, [:source, :x, :y]
  end
end
