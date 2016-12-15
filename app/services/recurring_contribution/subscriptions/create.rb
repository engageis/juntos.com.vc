class RecurringContribution::Subscriptions::Create
  def initialize(plan, project, user, payment_method, credit_card_hash)
    @plan = plan
    @project = project
    @user = user
    @payment_method = payment_method
    @credit_card_hash = credit_card_hash
  end

  def self.process(plan:, project:, user:, payment_method:, credit_card_hash: nil)
    new(plan, project, user, payment_method, credit_card_hash).process
  end

  def process
    pagarme_response = create_subscription_on_pagarme
    create_subscription_on_juntos(pagarme_response)
  end

  private
  attr_reader :plan, :project, :user, :payment_method, :credit_card_hash

  def create_subscription_on_pagarme
    RecurringContribution::Subscriptions::CreatePagarme.new(plan.plan_code, user, payment_method, credit_card_hash).process
  end

  def create_subscription_on_juntos(pagarme_response)
    juntos_subscription_service(project, pagarme_response).process
  end

  def juntos_subscription_service(project, pagarme_response)
    RecurringContribution::Subscriptions::CreateJuntos.new(project, pagarme_response)
  end
end
