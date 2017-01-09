class RecurringContribution::ChargingSubscriptionWorker
  include Sidekiq::Worker
  sidekiq_options retry: 2

  def perform
    Subscription.charging_day_reached.each do |juntos_subscription|
      process_subscription_creation(juntos_subscription)
    end
  end

  private

  def process_subscription_creation(juntos_subscription)
    RecurringContribution::Subscriptions::Create.process(juntos_subscription)
  rescue RecurringContribution::Subscriptions::UpdateJuntos::InvalidPagarmeSubscription
    log_error_message(juntos_subscription, "An invalid subscription was sent by PagarMe")
  rescue Pagarme::API::ResourceNotFound
    log_error_message(juntos_subscription, "The subscription's plan does not exist on PagarMe's database")
  rescue Pagarme::API::InvalidAttributeError => e
    log_error_message(juntos_subscription, "Invalid attributes sent: #{e}")
  rescue Pagarme::API::ConnectionError
    log_error_message(juntos_subscription, "A problem occurs on connection with PagarMe's API")
  end

  def log_error_message(subscription, message)
    Rails.logger.error "[RecurringContribution::ChargingSubscriptionWorker] ID: #{subscription.id} DESCRIPTION: #{message}"
  end
end
