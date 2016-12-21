class TransactionsController < ApplicationController
  def update_status
    transaction = Transaction.find_by(transaction_code: params[:id])
    RecurringContribution::UpdateStatus.process(request, transaction)
    render nothing: true, status: :ok
  rescue RecurringContribution::UpdateStatus::InvalidRequestError
    render json: { error: 'invalid postback' }, status: :bad_request
  end
end
