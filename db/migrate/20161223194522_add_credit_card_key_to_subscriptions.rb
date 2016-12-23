class AddCreditCardKeyToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :credit_card_key, :string
  end
end
