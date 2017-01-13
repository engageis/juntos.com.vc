class AddChargesAndExpiresAtToSubscriptions < ActiveRecord::Migration
  def up
    add_column :subscriptions, :charges, :integer, default: 0
    add_column :subscriptions, :expires_at, :date
  end

  def down
    remove_column :subscriptions, :charges
    remove_column :subscriptions, :expires_at
  end
end
