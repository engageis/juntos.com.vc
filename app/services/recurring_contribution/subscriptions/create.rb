class RecurringContribution::Subscriptions::Create
  def initialize(juntos_subscription)
    @juntos_subscription = juntos_subscription
  end

  def self.process(juntos_subscription)
    new(juntos_subscription).process
  end

  def process
    pagarme_response = create_subscription_on_pagarme
    update_juntos_subscription(pagarme_response)
  end

  private
  attr_reader :juntos_subscription

  def create_subscription_on_pagarme
    RecurringContribution::Subscriptions::CreatePagarme.new(juntos_subscription).process
  end

  def update_juntos_subscription(pagarme_response)
    juntos_subscription_service(juntos_subscription, pagarme_response).process
  end

  def juntos_subscription_service(juntos_subscription, pagarme_response)
    RecurringContribution::Subscriptions::UpdateJuntos.new(juntos_subscription, pagarme_response)
  end
end
