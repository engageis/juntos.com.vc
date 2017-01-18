class RecurringContribution::UpdatePlans
  def self.call
    new.call
  end

  def call
    Plan.transaction do
      pagarme_plans.map do |plan|
        build_plan(plan) unless plan_exist?(plan)
      end.compact
    end
  end

  private

  def build_plan(plan)
    normalize_payment_methods(plan)
    Plan.create(plan_code: plan.id, name: plan.name, amount: plan.amount, payment_methods: plan.payment_methods)
  end

  def normalize_payment_methods(plan)
    if plan.payment_methods.include? 'boleto'
      plan.payment_methods.each { |payment_method| payment_method.gsub!('boleto', 'bank_billet') }
    end
  end

  def pagarme_plans
    Pagarme::API.fetch_plans
  end

  def plan_exist?(plan)
    Plan.exists?(plan_code: plan.id)
  end
end
