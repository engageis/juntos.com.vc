class Pagarme::Request::Subscription < Pagarme::Request::Pagarme

  class << self
    def retrieve_pagarme_subscriptions(subscriptions_ids)
      subscription_request = request_params_for_get(subscriptions_ids, "subscriptions")
      response = post_pagarme_request(subscription_request)
      response_formatter(response.body)
    end

    def cancel_subscriptions(subscriptions_ids)
      return if subscriptions_ids.empty?

      cancel_request = request_params_for_cancel(subscriptions_ids, "subscriptions")
      post_pagarme_request(cancel_request)
    end
  end
end
