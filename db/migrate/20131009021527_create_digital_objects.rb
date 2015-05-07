class CreateDigitalObjects < ActiveRecord::Migration
  def change
    create_table :digital_objects do |t|
      t.text :location

      t.timestamps
    end
  end
end
