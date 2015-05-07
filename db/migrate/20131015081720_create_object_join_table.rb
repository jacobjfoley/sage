class CreateObjectJoinTable < ActiveRecord::Migration
  def change
    create_join_table :digital_objects, :concepts do |t|
      t.index [:digital_object_id, :concept_id], name: "object_concept"
      t.index [:concept_id, :digital_object_id], name: "concept_object"
    end
  end
end
