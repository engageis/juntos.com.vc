class RecurringContribution::Subscriptions::UpdateJuntos
  class InvalidPagarmeSubscription < StandardError; end

  attr_reader :juntos_subscription, :pagarme_subscription

  def initialize(juntos_subscription, pagarme_subscription)
    @juntos_subscription = juntos_subscription
    @pagarme_subscription = pagarme_subscription
  end

  def process
    update_subscription_and_create_its_transaction if valid_pagarme_subscription?
  end

  private

  def update_subscription_and_create_its_transaction
    Subscription.transaction do
      update_subscription
      create_transaction
      juntos_subscription
    end
  end

  def update_subscription
    juntos_subscription.update(
      subscription_code: pagarme_subscription.id,
      status:            pagarme_subscription.status,
      expires_at:        expires_at
    )
  end

  def create_transaction
    transaction = Transaction.new(
      transaction_code: pagarme_subscription.current_transaction.id,
      status:           pagarme_subscription.current_transaction.status,
      amount:           pagarme_subscription.current_transaction.amount
    )

    juntos_subscription.transactions << transaction
  end

  def valid_pagarme_subscription?
    (pagarme_subscription && pagarme_subscription.id) || raise(InvalidPagarmeSubscription.new)
  end

  def expires_at
    return if juntos_subscription.charges.zero?
    Date.parse(pagarme_subscription.current_period_start) + juntos_subscription.charges.month
  end
end
