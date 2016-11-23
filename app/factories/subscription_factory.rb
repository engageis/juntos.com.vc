class SubscriptionFactory
  class << self
    def build(type, plan, user, payment_method, project = nil)
      new(type, plan, user, payment_method, project).build
    end

    private :new
  end

  def initialize(type, plan, user, payment_method, project)
    @type = type
    @plan = plan
    @user = user
    @payment_method = payment_method
    @project = project
  end

  def build
    case @type
    when :juntos
      build_juntos_subscription
    when :pagarme
      build_pagarme_subscription
    end
  end

  private

  def build_juntos_subscription
    Subscription.new(plan: @plan, user: @user, payment_method: @payment_method, project: @project)
  end

  def build_pagarme_subscription
    PagarMe::Subscription.new({
      plan: RecurringContribution::PagarmeAPI.find_plan(@plan.plan_code),
      payment_method: normalize_payment_method(@payment_method),
      postback_url: "http://test.com/postback",
      customer: { email: @user.email }
      })
  end

  def normalize_payment_method(payment_method)
    bank_billet? ? 'boleto' : payment_method
  end

  def bank_billet?
    @payment_method == 'bank_billet'
  end
end
