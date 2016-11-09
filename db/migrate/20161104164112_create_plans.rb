class CreatePlans < ActiveRecord::Migration
  def change
    create_table :plans do |t|
      t.integer :plan_code
      t.string  :name
      t.decimal :amount
      t.integer :payment_methods, array: true, default: []
      t.timestamps
    end
  end
end
