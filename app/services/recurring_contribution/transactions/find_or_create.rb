class RecurringContribution::Transactions::FindOrCreate
  attr_reader :transaction_code

  def initialize(transaction_code)
    @transaction_code = transaction_code
  end

  def self.process(transaction_code)
    new(transaction_code).process
  end

  def process
    Transaction.find_by(transaction_code: transaction_code) || create_transaction
  end

  private

  def create_transaction
    pagarme_transaction = Pagarme::API.find_transaction(transaction_code)
    subscription = Subscription.find_by(subscription_code: pagarme_transaction.subscription_id)

    Transaction.create({
                         transaction_code: pagarme_transaction.id,
                         status: pagarme_transaction.status,
                         amount: pagarme_transaction.amount,
                         payment_method: pagarme_transaction.payment_method,
                         subscription: subscription
                        })
  end
end
