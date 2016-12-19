class SubscriptionsController < ApplicationController
  def update_status
    subscription = Subscription.find_by(subscription_code: params[:id])
    RecurringContribution::UpdateStatus.process(request, subscription)
    render nothing: true, status: :ok
  rescue RecurringContribution::UpdateStatus::InvalidRequestError
    render json: { error: 'invalid postback' }, status: :bad_request
  end
end
