class AddAuthorizedToBankAccounts < ActiveRecord::Migration
  def change
    add_column :bank_accounts, :authorized, :boolean, default: false
  end
end
