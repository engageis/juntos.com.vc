class RecurringContribution::JuntosSubscription
  def initialize(juntos_subscription, pagarme_subscription)
    @pagarme_subscription = pagarme_subscription
    @juntos_subscription = juntos_subscription
  end

  def process
    Subscription.transaction do
      @juntos_subscription.subscription_code = @pagarme_subscription.id
      @juntos_subscription.status = @pagarme_subscription.status
      @juntos_subscription.save
      @juntos_subscription.transactions.build(transaction_code: @pagarme_subscription.current_transaction.id,
                                              status: @pagarme_subscription.current_transaction.status,
                                              amount: @pagarme_subscription.current_transaction.amount)
      @juntos_subscription
    end
  end
end
