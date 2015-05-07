class CreateUserRoles < ActiveRecord::Migration
  def change
    create_table :user_roles do |t|
      t.integer :user_id
      t.integer :project_id

      t.timestamps
    end
    add_index :user_roles, :user_id
    add_index :user_roles, :project_id
  end
end
