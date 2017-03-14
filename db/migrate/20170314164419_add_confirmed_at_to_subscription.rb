class AddConfirmedAtToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :confirmed_at, :datetime, default: nil
  end
end
