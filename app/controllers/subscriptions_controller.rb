class SubscriptionsController < ApplicationController
  def update_status
    RecurringContribution::Subscriptions::UpdateStatus.process(request)
    render nothing: true, status: :ok
  rescue RecurringContribution::Subscriptions::UpdateStatus::InvalidRequestError
    render json: { error: 'invalid postback' }, status: :bad_request
  end
end
