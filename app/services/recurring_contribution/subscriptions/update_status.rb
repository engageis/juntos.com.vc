class RecurringContribution::Subscriptions::UpdateStatus
  class InvalidRequestError < StandardError; end

  def initialize(request)
    @juntos_subscription = Subscription.find_by(subscription_code: request.params[:id])
    @current_status = request.params[:current_status]
    @request = request
  end

  def self.process(request)
    new(request).process
  end

  def process
    update_status if request_source_is_pagarme?
  end

  private

  def update_status
    @juntos_subscription.update(status: @current_status)
    @juntos_subscription
  end

  def request_source_is_pagarme?
    Pagarme::API.valid_request_signature?(@request) || (raise InvalidRequestError.new)
  end
end
