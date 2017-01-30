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
    @project = Project.find(params[:project_id]).decorate
    @subscription = Subscription.new(user: current_user, project: @project)
    authorize @subscription
  end

  def create
    @subscription = Subscription.new
    @subscription.user = current_user
    @subscription.assign_attributes(subscription_params)

    authorize @subscription

    @subscription = RecurringContribution::Subscriptions::Processor.process(
      subscription: @subscription,
      credit_card_hash: credit_card_params
    )

    if @subscription.errors.any?
      flash[:alert] = @subscription.errors.full_messages.to_sentence
      redirect_to new_project_subscription_path project_id: params[:project_id]
    else
      flash[:notice] = t('project.subscription.create.success')
      redirect_to project_path @subscription.project
    end
  end

  def cancel
    subscription = Subscription.find(params[:subscription][:id])
    authorize subscription

    RecurringContribution::Subscriptions::Cancel.process(subscription)

    flash[:notice] = t('project.subscription.cancel.success')

    redirect_to_user_path(subscription.user)

  rescue Pagarme::API::ResourceNotFound
    flash[:notice] = t('project.subscription.cancel.errors.not_found')
    redirect_to_user_path(subscription.user)
  rescue Pagarme::API::ConnectionError
    flash[:notice] = t('project.subscription.cancel.errors.connection_fails')
    redirect_to_user_path(subscription.user)
  end

  private

  def subscription_params
    params.require(:subscription).permit(policy(@subscription).permitted_attributes)
  end

  def credit_card_params
    params.require(:subscription).permit(policy(@subscription).credit_card_permitted_attributes) || {}
  end

  def use_catarse_boostrap
    action_name.eql?('new') ? 'juntos_bootstrap' : 'application'
  end

  def redirect_to_user_path(user)
    redirect_to user_path(user)
  end
end
