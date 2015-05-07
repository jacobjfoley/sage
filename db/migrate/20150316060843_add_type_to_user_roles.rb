class AddTypeToUserRoles < ActiveRecord::Migration
  def change
    add_column :user_roles, :position, :string
  end
end
