class RecurringContribution::PagarmeSubscription
  def initialize(pagarme_subscription, credit_card)
    @credit_card = credit_card
    @pagarme_subscription = pagarme_subscription
  end

  def process
    RecurringContribution::PagarmeAPI.create_subscription(attributes)
  end

  private

  def attributes
    return default_attributes.merge(credit_card_attributes) if credit_card?
    default_attributes
  end

  def default_attributes
    @pagarme_subscription.instance_values
  end

  def credit_card_attributes
    @credit_card.slice(:card_number, :card_holder_name, :card_expiration_month, :card_expiration_year, :card_cvv)
  end

  def credit_card?
    @payment_method == 'credit_card'
  end
end
