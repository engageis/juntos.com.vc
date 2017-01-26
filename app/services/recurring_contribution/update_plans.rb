class RecurringContribution::UpdatePlans
  def self.call
    new.call
  end

  def call
    pagarme_plans.each do |plan|
      save(plan) if nontrialing?(plan)
    end
  end

  private

  def save(plan)
    normalize_payment_methods(plan)
    Plan.create(plan_code: plan.id, name: plan.name, amount: plan.amount, payment_methods: plan.payment_methods)
  end

  def normalize_payment_methods(plan)
    plan.payment_methods.index('boleto').tap do |index|
      plan.payment_methods[index] = 'bank_billet' unless index.nil?
    end
  end

  def pagarme_plans
    Pagarme::API.fetch_plans
  end

  def nontrialing?(plan)
    plan.trial_days.zero?
  end
end
