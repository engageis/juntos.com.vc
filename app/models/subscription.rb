class Subscription < ActiveRecord::Base
  extend Enumerize

  validates_presence_of :status, :payment_method, :charging_day,
                        :plan_id, :user_id, :project_id

  validates_inclusion_of :payment_method, in: 'permitted_payment_methods',
                                          unless: 'plan.nil?'

  validates_numericality_of :charging_day, less_than_or_equal_to: 28, greater_than: 0

  enumerize :payment_method, in: { credit_card: 0, bank_billet: 1 }

  enumerize :status, in: { paid: 0, pending_payment: 1, unpaid: 2, canceled: 3, waiting_for_charging_day: 4 }

  has_many   :transactions
  belongs_to :user
  belongs_to :project
  belongs_to :plan

  private

  def permitted_payment_methods
    plan.payment_methods
  end
end
