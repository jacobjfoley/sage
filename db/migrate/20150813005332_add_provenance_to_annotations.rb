class AddProvenanceToAnnotations < ActiveRecord::Migration
  def change
    add_column :annotations, :provenance, :string
  end
end
