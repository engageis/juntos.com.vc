class RecurringContribution::CancelSubscriptionWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    return if expired_subscriptions.empty?
    RecurringContribution::Subscriptions::CancelExpired.process(expired_subscriptions)
  end

  private

  def expired_subscriptions
    @expired_subscriptions ||= Subscription.expired.each_with_object({}) do |subscription, expired_subscriptions|
      expired_subscriptions[subscription.subscription_code] = subscription
    end
  end
end
