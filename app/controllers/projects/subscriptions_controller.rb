class Projects::SubscriptionsController < ApplicationController
  after_filter :verify_authorized, except: [ :update_status ]

  def update_status
    subscription = Subscription.find_by(subscription_code: params[:id])
    RecurringContribution::UpdateStatus.process(request, subscription)
    render nothing: true, status: :ok
  rescue RecurringContribution::UpdateStatus::InvalidRequestError
    render json: { error: 'invalid postback' }, status: :bad_request
  end

  def new
    @subscription = Subscription.new(user: current_user)
    authorize @subscription

    render nothing: true
  end

  def create
    subscription = Subscription.new subscription_params
    subscription.user = current_user

    authorize subscription

    @subscription = RecurringContribution::Subscriptions::Processor.process(
      subscription: subscription,
      credit_card_hash: credit_card_params
    )

    if @subscription.errors.any?
      flash[:alert] = @subscription.errors.full_messages.to_sentence
      render nothing: true
    else
      flash[:notice] = t('project.subscription.create.success')
      redirect_to project_path @subscription.project
    end
  end

  def cancel
    subscription = Subscription.find(params[:id])
    authorize subscription

    RecurringContribution::Subscriptions::CancelOnPagarme.process(subscription)

    flash[:notice] = t('project.subscription.cancel.success')

    render nothing: true

  rescue Pagarme::API::ResourceNotFound
    flash[:notice] = t('project.subscription.cancel.errors.not_found')
    render nothing: true
  rescue Pagarme::API::ConnectionError
    flash[:notice] = t('project.subscription.cancel.errors.connection_fails')
    render nothing: true
  end

  private

  def subscription_params
    params.require(:subscription).permit(:plan_id, :project_id, :user_id, :payment_method, :charging_day)
  end

  def credit_card_params
    params.require(:subscription).permit(:cedit_card_hash) || {}
  end
end
