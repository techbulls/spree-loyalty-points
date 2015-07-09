class RemoveLockVersionFromSpreeUser < ActiveRecord::Migration
  def change
  	remove_column :spree_users, :lock_version, :integer
  end
end
