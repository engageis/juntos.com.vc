class Pagarme::API
  class << self
    def find_plan(plan_id)
      PagarMe::Plan.find_by_id(plan_id)
    end

    def create_subscription(attributes)
      PagarMe::Subscription.create(attributes)
    end

    def valid_request_signature?(request)
      payload = request.raw_post
      signature = request.headers['HTTP_X_HUB_SIGNATURE'] || ""

      PagarMe::Postback.valid_request_signature?(payload, signature)
    end
  end
end
