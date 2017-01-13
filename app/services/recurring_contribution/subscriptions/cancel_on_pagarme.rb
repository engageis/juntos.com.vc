class RecurringContribution::Subscriptions::CancelOnPagarme
  def initialize(juntos_subscription)
    @juntos_subscription = juntos_subscription
  end

  def self.process(juntos_subscription)
    new(juntos_subscription).process
  end

  def process
    pagarme_subscription = Pagarme::API.find_subscription(@juntos_subscription.subscription_code)
    Pagarme::API.cancel_subscription(pagarme_subscription)
  end
end
