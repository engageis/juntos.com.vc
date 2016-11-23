class Pagarme::API
  class << self
    def find_plan(plan_id)
      PagarMe::Plan.find_by_id(plan_id)
    end

    def create_subscription(attributes)
      PagarMe::Subscription.create(attributes)
    end
  end
end
