class DropAssociationJoinTable < ActiveRecord::Migration
  def change
    drop_join_table :concepts, :digital_objects
  end
end
