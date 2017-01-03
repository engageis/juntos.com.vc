class Plan < ActiveRecord::Base
  attr_accessible :plan_code, :name, :amount, :payment_methods

  extend Enumerize
  extend ActiveModel::Naming

  enumerize :payment_methods,
            in: { credit_card: 0, bank_billet: 1 },
            multiple: true, i18n_scope: "enumerize.plan.payment_methods"

  validates_presence_of :plan_code, :name, :amount, :payment_methods

  has_and_belongs_to_many :projects, join_table: 'projects_plans'
end
