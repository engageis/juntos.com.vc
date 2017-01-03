class CreateProjectsPlans < ActiveRecord::Migration
  def change
    create_table :projects_plans do |t|
      t.integer :project_id
      t.integer :plan_id
    end

    add_index :projects_plans, :project_id
    add_index :projects_plans, :plan_id
  end
end
