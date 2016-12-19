class RecurringContribution::UpdateServicesBase
  class InvalidRequestError < StandardError; end

  def initialize(request)
    @request = request
    @current_status = request.params[:current_status]
  end

  private

  def update_status
    resource.update(status: @current_status)
    resource
  end

  def request_source_is_pagarme?
    Pagarme::API.valid_request_signature?(@request) || raise(InvalidRequestError.new)
  end

  def resource
    raise NotImplementedError
  end
end
