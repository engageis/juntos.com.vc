class CreateSubscriptionReports < ActiveRecord::Migration
  def change
    create_table :subscription_reports do |t|
      t.text :attachment
      t.references :project, index: true

      t.timestamps
    end
  end
end
