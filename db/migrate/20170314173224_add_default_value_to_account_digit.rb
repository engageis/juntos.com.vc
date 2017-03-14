class AddDefaultValueToAccountDigit < ActiveRecord::Migration
  def change
    change_column_default :bank_accounts, :account_digit, 0
  end
end
