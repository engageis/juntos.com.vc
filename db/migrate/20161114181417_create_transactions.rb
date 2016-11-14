class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.integer :transaction_code
      t.integer :status, limit: 1, default: 0
      t.decimal :amount
      t.integer :payment_method, limit: 1, default: 0
      t.references :subscription, index: true

      t.timestamps
    end
  end
end
