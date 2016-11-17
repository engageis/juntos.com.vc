class RecurringContribution::PagarmeSubscription
  def initialize(plan_id, user, payment_method, credit_card)
    @credit_card = credit_card
    @payment_method = normalize_payment_method(payment_method)
    @plan_id = plan_id
    @user = user
  end

  def build
    RecurringContribution::PagarmeAPI.create_subscription(attributes)
  end

  private

  def attributes
    return default_attributes.merge(credit_card_attributes) if credit_card?
    default_attributes
  end

  def default_attributes
    {
      plan: RecurringContribution::PagarmeAPI.find_plan(@plan_id),
      payment_method: @payment_method,
      postback_url: "http://test.com/postback",
      customer: { email: @user.email }
    }
  end

  def credit_card_attributes
    @credit_card.slice(:card_number, :card_holder_name, :card_expiration_month, :card_expiration_year, :card_cvv)
  end

  def normalize_payment_method(payment_method)
    bank_billet? ? 'boleto' : payment_method
  end

  def credit_card?
    @payment_method == 'credit_card'
  end

  def bank_billet?
    @payment_method == 'bank_billet'
  end
end
