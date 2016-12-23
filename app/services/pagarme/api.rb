class Pagarme::API
  class ConnectionError       < StandardError; end
  class ResourceNotFound      < StandardError; end
  class InvalidAttributeError < StandardError; end

  class << self
    def find_plan(plan_id)
      PagarMe::Plan.find_by_id(plan_id)
    rescue PagarMe::ConnectionError
      raise_connection_error
    rescue PagarMe::NotFound
      raise ResourceNotFound
    end

    def create_subscription(attributes)
      PagarMe::Subscription.create(attributes)
    rescue PagarMe::ConnectionError
      raise_connection_error
    rescue PagarMe::ValidationError => e
      raise InvalidAttributeError, e.message
    end

    def valid_request_signature?(request)
      payload = request.raw_post
      signature = request.headers['HTTP_X_HUB_SIGNATURE'] || ""

      PagarMe::Postback.valid_request_signature?(payload, signature)
    rescue PagarMe::ConnectionError
      raise_connection_error
    end

    def create_credit_card(attributes)
      PagarMe::Card.create(attributes)
    rescue PagarMe::ConnectionError
      raise_connection_error
    rescue PagarMe::ValidationError => e
      raise InvalidAttributeError, e.message
    end

    private

    def raise_connection_error
      raise ConnectionError, 'The connection with our payment server was lost'
    end
  end
end
