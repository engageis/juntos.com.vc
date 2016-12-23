class AddChargingDayToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :charging_day, :integer
  end
end
