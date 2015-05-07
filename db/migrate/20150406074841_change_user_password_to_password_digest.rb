class ChangeUserPasswordToPasswordDigest < ActiveRecord::Migration
  def change
    rename_column :users, :password, :password_digest
    remove_column :users, :salt, :string
  end
end
