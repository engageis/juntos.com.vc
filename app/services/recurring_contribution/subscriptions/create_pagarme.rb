class RecurringContribution::Subscriptions::CreatePagarme
  def initialize(juntos_subscription, credit_card = nil)
    @credit_card = credit_card
    @payment_method = normalize_payment_method(juntos_subscription.payment_method)
    @plan_id = juntos_subscription.plan.plan_code
    @user = juntos_subscription.user
  end

  def process
    ::Pagarme::API.create_subscription(attributes)
  end

  private

  def attributes
    return default_attributes.merge(credit_card_attributes) if credit_card?
    default_attributes
  end

  def default_attributes
    {
      plan: ::Pagarme::API.find_plan(@plan_id),
      payment_method: @payment_method,
      postback_url: postback_url,
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

  def postback_url
    Rails.application.routes.url_helpers.subscription_status_update_url
  end
end
