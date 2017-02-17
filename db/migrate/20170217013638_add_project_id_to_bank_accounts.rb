class AddProjectIdToBankAccounts < ActiveRecord::Migration
  def change
    add_column :bank_accounts, :project_id, :integer
  end
end
