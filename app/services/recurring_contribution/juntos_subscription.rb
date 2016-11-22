class RecurringContribution::JuntosSubscription
  def initialize(project, plan, user, payment_method)
    @project = project
    @plan = plan
    @user = user
    @payment_method = payment_method
  end

  def process(pagarme_subscription)
    Subscription.transaction do
      juntos_subscription = create_subscription(pagarme_subscription)
      juntos_subscription.transactions.build(transaction_code: pagarme_subscription.current_transaction.id,
                                             status: pagarme_subscription.current_transaction.status,
                                             amount: pagarme_subscription.current_transaction.amount)
      juntos_subscription
    end
  end

  private

  def create_subscription(pagarme_subscription)
    Subscription.create(subscription_code: pagarme_subscription.id, status: pagarme_subscription.status,
                        payment_method: @payment_method, plan: @plan, project: @project, user: @user)
  end
end
