class AddActiveToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :active, :boolean, default: true
  end
end
