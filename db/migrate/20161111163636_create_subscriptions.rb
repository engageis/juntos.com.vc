class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.integer :subscription_code
      t.integer :payment_method, default: 0
      t.integer :status, default: 0
      t.references :plan, index: true
      t.references :user, index: true
      t.references :project, index: true

      t.timestamps
    end
  end
end
