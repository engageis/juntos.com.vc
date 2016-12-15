class RecurringContribution::Subscriptions::UpdateStatus
  def initialize(subscription_code, current_status)
    @juntos_subscription = Subscription.find_by(subscription_code: subscription_code)
    @current_status = current_status
  end

  def self.process(subscription_code, current_status)
    new(subscription_code, current_status).process
  end

  def process
    @juntos_subscription.update(status: @current_status)
    @juntos_subscription
  end
end
