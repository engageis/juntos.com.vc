class RecurringContribution::Subscriptions::CancelExpired
  attr_reader :subscriptions

  def initialize(subscriptions)
    @subscriptions = subscriptions
  end

  def self.process(subscriptions)
    new(subscriptions).process
  end

  def process
    pagarme_subscriptions = Pagarme::Request::Subscription.retrieve_pagarme_subscriptions(subscriptions.keys)
    canceled_subscriptions_ids = cancelable_subscriptions(pagarme_subscriptions, subscriptions)

    Pagarme::Request::Subscription.cancel_subscriptions(canceled_subscriptions_ids)
  end

  private

  def cancelable_subscriptions(pagarme_subscriptions, subscriptions)
    pagarme_subscriptions.each_with_object([]) do |pagarme_subscription, canceled_subscriptions|
      subscription = subscriptions[pagarme_subscription[:id]]

      if cancelable?(pagarme_subscription[:charges], subscription)
        canceled_subscriptions << subscription.subscription_code
      end
    end
  end

  def cancelable?(pagarme_charges, subscription)
    return credit_card_charges_reached?(pagarme_charges, subscription.charges) if subscription.credit_card?
    return bank_billet_charges_reached?(pagarme_charges, subscription.charges)
  end

  def credit_card_charges_reached?(pagarme_charges, subscription_charges)
    pagarme_charges == subscription_charges - 1
  end

  def bank_billet_charges_reached?(pagarme_charges, subscription_charges)
    subscription_charges == pagarme_charges
  end
end
