class RecurringContribution::Subscriptions::Cancel
  def initialize(subscription)
    @subscription = subscription
  end

  def self.process(subscription)
    new(subscription).process
  end

  def process
    pagarme? ? cancel_on_pagarme : cancel_on_juntos
  end

  private

  def pagarme?
    !@subscription.subscription_code.nil?
  end

  def cancel_on_pagarme
    pagarme_subscription = Pagarme::API.find_subscription(@subscription.subscription_code)
    Pagarme::API.cancel_subscription(pagarme_subscription)
  end

  def cancel_on_juntos
    @subscription.canceled!
  end
end
