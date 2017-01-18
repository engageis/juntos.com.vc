class Subscription < ActiveRecord::Base
  validates_presence_of :status, :payment_method, :charging_day,
                        :plan_id, :user_id, :project_id

  validates_inclusion_of :payment_method, in: 'permitted_payment_methods',
                                          unless: 'plan.nil?'

  validates_numericality_of :charging_day, less_than_or_equal_to: 28, greater_than: 0

  enum payment_method: [ :credit_card, :bank_billet ]

  enum status: [ :pending_payment, :paid, :unpaid, :canceled, :waiting_for_charging_day ]

  has_many   :transactions
  belongs_to :user
  belongs_to :project
  belongs_to :plan

  scope :charged_at_least_once, -> { where.not(status: Subscription.statuses[:waiting_for_charging_day]) }
  scope :charging_day_reached, -> { waiting_for_charging_day.where(charging_day: DateTime.current.day) }

  scope :expired, -> { paid.where("expires_at <= ?", Date.current) }

  private

  def permitted_payment_methods
    plan.payment_methods
  end
end
