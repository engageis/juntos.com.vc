class RecurringContribution::Transactions::UpdateStatus < RecurringContribution::UpdateServicesBase
  def initialize(request)
    super(request)
  end

  def self.process(request)
    new(request).process
  end

  def process
    update_status if request_source_is_pagarme?
  end

  private

  def resource
    @transaction ||= Transaction.find_by(transaction_code: @request.params[:id])
  end
end
