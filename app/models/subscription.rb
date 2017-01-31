class Subscription < ActiveRecord::Base
  validates_presence_of :status, :payment_method, :charging_day,
                        :plan_id, :user_id, :project_id

  validates_inclusion_of :payment_method, in: 'permitted_payment_methods',
                                          unless: 'plan.nil?'

  validates_numericality_of :charging_day, less_than_or_equal_to: 28, greater_than: 0

  enum payment_method: [ :credit_card, :bank_billet ]

  enum status: [ :pending_payment, :paid, :unpaid, :canceled, :waiting_for_charging_day ]

  ACCEPTED_CHARGE_OPTIONS = {
    indefinite:       0,
    for_three_months: 3,
    for_six_months:   6,
    for_a_year:       12
  }

  has_many   :transactions
  belongs_to :user
  belongs_to :project
  belongs_to :plan

  scope :charging_day_reached,  -> { waiting_for_charging_day.where(charging_day: DateTime.current.day) }
  scope :expired,               -> { paid.where("expires_at <= ?", Date.current) }

  def self.accepted_charge_options
    {}.tap do |h|
      ACCEPTED_CHARGE_OPTIONS.each do |k, v|
        h[human_attribute_name("charge_options.#{k}")] = v
      end
    end
  end

  def available_for_canceling?
    !canceled?
  end

  private

  def permitted_payment_methods
    plan.payment_methods
  end
end
