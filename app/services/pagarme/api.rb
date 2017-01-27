class Pagarme::API
  class ConnectionError       < StandardError; end
  class ResourceNotFound      < StandardError; end
  class InvalidAttributeError < StandardError; end

  class << self
    def fetch_plans
      PagarMe::Plan.all(1, 100)
    rescue PagarMe::ConnectionError
      raise_connection_error
    end

    def find_plan(plan_id)
      rescue_not_found { PagarMe::Plan.find_by_id(plan_id) }
    end

    def find_subscription(subscription_id)
      rescue_not_found { PagarMe::Subscription.find_by_id(subscription_id) }
    end

    def find_transaction(transaction_id)
      rescue_not_found { PagarMe::Transaction.find_by_id(transaction_id) }
    end

    def create_subscription(attributes)
      rescue_invalid_attribute { PagarMe::Subscription.create(attributes) }
    end

    def create_credit_card(attributes)
      rescue_invalid_attribute { PagarMe::Card.create(attributes) }
    end

    def valid_request_signature?(request)
      payload = request.raw_post
      signature = request.headers['HTTP_X_HUB_SIGNATURE'] || ""

      PagarMe::Postback.valid_request_signature?(payload, signature)
    rescue PagarMe::ConnectionError
      raise_connection_error
    end

    def cancel_subscription(pagarme_subscription)
      pagarme_subscription.cancel
    rescue PagarMe::RequestError, NoMethodError
      raise ResourceNotFound
    end

    private

    def rescue_not_found
      yield
    rescue PagarMe::ConnectionError
      raise_connection_error
    rescue PagarMe::NotFound, PagarMe::RequestError
      raise ResourceNotFound
    end

    def rescue_invalid_attribute
      yield
    rescue PagarMe::ConnectionError
      raise_connection_error
    rescue PagarMe::ValidationError => e
      raise InvalidAttributeError, e.message
    end

    def raise_connection_error
      raise ConnectionError, 'The connection with our payment server was lost'
    end
  end
end
