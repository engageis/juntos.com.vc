class RecurringContribution::Subscriptions::Juntos
  attr_reader :juntos_data, :project

  def initialize(project, juntos_data)
    @project = project
    @juntos_data = juntos_data
  end

  def process
    Subscription.transaction do
      juntos_subscription = create_subscription
      create_transaction(juntos_subscription)
      juntos_subscription
    end
  end

  private

  def create_subscription
    Subscription.create(
      subscription_code: juntos_data.pagarme_subscription.id,
      status:            juntos_data.pagarme_subscription.status,
      payment_method:    juntos_data.payment_method,
      plan:              juntos_data.plan,
      project:           project,
      user:              juntos_data.user
    )
  end

  def create_transaction(juntos_subscription)
    transaction = Transaction.new(
      transaction_code: juntos_data.pagarme_transaction.id,
      status:           juntos_data.pagarme_transaction.status,
      amount:           juntos_data.pagarme_transaction.amount
    )

    juntos_subscription.transactions << transaction
  end
end
