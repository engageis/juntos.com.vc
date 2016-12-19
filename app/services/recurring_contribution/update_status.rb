class RecurringContribution::UpdateStatus
  class InvalidRequestError < StandardError; end

  def initialize(request, resource)
    @request = request
    @current_status = request.params[:current_status]
    @resource = resource
  end

  def self.process(request, resource)
    new(request, resource).process
  end

  def process
    update_status if request_source_is_pagarme?
  end

  private

  def update_status
    @resource.update(status: @current_status)
    @resource
  end

  def request_source_is_pagarme?
    Pagarme::API.valid_request_signature?(@request) || raise(InvalidRequestError.new)
  end
end
