class RenameAssociationsToAnnotations < ActiveRecord::Migration
  def change
    rename_table "associations", "annotations"
  end
end
