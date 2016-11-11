class Subscription < ActiveRecord::Base
  extend Enumerize

  validates_presence_of :subscription_code, :status, :payment_method,
                        :plan_id, :user_id, :project_id

  validates_inclusion_of :payment_method, in: 'permitted_payment_methods',
                                          unless: 'plan.nil?'

  enumerize :payment_method, in: { credit_card: 0, bank_billet: 1 }

  enumerize :status, in: { paid: 0, pending_payment: 1, unpaid: 2, canceled: 3 }

  belongs_to :user
  belongs_to :project
  belongs_to :plan

  private

  def permitted_payment_methods
    plan.payment_methods
  end
end
