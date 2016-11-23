class RecurringContribution::Subscriptions::JuntosSubscriptionData
  extend Forwardable

  attr_reader :plan, :user, :payment_method, :pagarme_subscription

  def initialize(user, payment_method, subscription)
    @plan = Plan.find_by(plan_code: subscription.plan.id)
    @user = user
    @payment_method = payment_method
    @pagarme_subscription = subscription
  end

  def_delegator :@pagarme_subscription, :current_transaction, :pagarme_transaction
end
