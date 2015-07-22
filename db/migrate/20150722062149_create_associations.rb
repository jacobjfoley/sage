class CreateAssociations < ActiveRecord::Migration
  def change
    create_table :associations do |t|
      t.references :digital_object, index: true, foreign_key: true
      t.references :concept, index: true, foreign_key: true
      t.references :project, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
