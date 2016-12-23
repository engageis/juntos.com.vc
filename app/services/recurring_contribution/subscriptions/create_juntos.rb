class RecurringContribution::Subscriptions::CreateJuntos
  def initialize(project, plan, user, payment_method, charging_day, credit_card_attributes)
    @project = project
    @plan = plan
    @user = user
    @payment_method = payment_method
    @charging_day = charging_day
    @credit_card_attributes = credit_card_attributes
  end

  def self.process(project:, plan:, user:, payment_method:, charging_day:, credit_card_hash: {})
    new(project, plan, user, payment_method, charging_day, credit_card_hash).process
  end

  def process
    create_credit_card_on_pagarme if paid_with_credit_card?
    create_subscription
  end

  private
  attr_reader   :project, :payment_method, :plan, :user, :charging_day, :credit_card_attributes

  def create_subscription
    Subscription.create(
      status:            :waiting_for_charging_day,
      payment_method:    payment_method,
      plan:              plan,
      project:           project,
      user:              user,
      credit_card_key:   @credit_card_key,
      charging_day:      charging_day
    )
  end

  def create_credit_card_on_pagarme
    pagarme_response = Pagarme::API.create_credit_card(credit_card_attributes)
    @credit_card_key = pagarme_response.id
  end

  def paid_with_credit_card?
    payment_method == 'credit_card'
  end
end
