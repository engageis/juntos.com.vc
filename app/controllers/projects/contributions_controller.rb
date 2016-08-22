class Projects::ContributionsController < ApplicationController
  inherit_resources
  actions :index, :show, :new, :update, :review, :create
  skip_before_filter :verify_authenticity_token, only: [:moip]
  has_scope :available_to_count, type: :boolean
  has_scope :with_state
  #has_scope :page, default: 1
  after_filter :verify_authorized, except: [:index]
  belongs_to :project
  before_filter :detect_old_browsers, only: [:new, :create]
  before_filter :load_channel, only: [:edit, :new]
  before_action :set_country_payment_engine
  helper_method :avaiable_payment_engines

  def edit
    authorize resource
    resource.country_code = 'BR'
    @payment_engines = avaiable_payment_engines
    @countries = ISO3166::Country.all_names_with_codes(I18n.locale)

    if resource.preferred_payment_engine.present?
      @payment_engines.select! { |engine| engine.name == resource.preferred_payment_engine }
    end
    if resource.reward.try(:sold_out?)
      flash[:alert] = t('.reward_sold_out')
      return redirect_to new_project_contribution_path(@project)
    end
  end

  def update
    authorize resource
    resource.update_attributes(permitted_params[:contribution])
    resource.update_user_billing_info

    if @project.recurring?
      RecurringPaymentService.perform(resource.recurring_contribution.id,
                                      resource, params[:payment_card_hash])

      redirect_to obrigado_path
      return
    end

    render json: {message: 'updated'}
  end

  def index
    render collection
  end

  def show
    authorize resource
    @title = t('projects.contributions.show.title')
  end

  def new
    @create_url = project_contributions_url(@project, project_contribution_url_options)

    @contribution = Contribution.new(project: parent, user: current_user)
    authorize @contribution

    @title = t('projects.contributions.new.title', name: @project.name)
    load_rewards

    # Select
    if params[:reward_id] && (@selected_reward = @project.rewards.find params[:reward_id]) && !@selected_reward.sold_out?
      @contribution.reward = @selected_reward
      @contribution.project_value = "%0.0f" % @selected_reward.minimum_value
    end
  end

  def create
    Contribution.transaction do
      @title = t('projects.contributions.create.title')
      @contribution = parent.contributions.new.localized
      @contribution.user = current_user
      @contribution.project_value = permitted_params[:contribution][:project_value]
      @contribution.platform_value = permitted_params[:contribution][:platform_value]
      @contribution.preferred_payment_engine = permitted_params[:contribution][:preferred_payment_engine]
      @contribution.reward_id = (params[:contribution][:reward_id].to_i == 0 ? nil : params[:contribution][:reward_id])
      authorize @contribution
      @contribution.update_current_billing_info
      create! do |success,failure|
        failure.html do
          flash[:alert] = resource.errors.full_messages.to_sentence
          load_rewards
          render :new
        end
        success.html do
          if @project.recurring?
            RecurringContributionService.create(@contribution)
          end

          flash[:notice] = nil
          session[:thank_you_contribution_id] = @contribution.id
          session[:new_contribution] = true;
          return redirect_to edit_project_contribution_path(project_id: @project.id, id: @contribution.id)
        end
      end
      @thank_you_id = @project.id
    end
  end

  protected
  def load_channel
    @channel = parent.channels.first
  end

  def load_rewards
    empty_reward = Reward.new(minimum_value: 0, description: t('projects.contributions.new.no_reward'))
    @rewards = [empty_reward] + @project.rewards.remaining.order(:minimum_value)
  end

  def permitted_params
    params.permit(policy(resource).permitted_attributes)
  end

  def avaiable_payment_engines
    engines = []

    if resource.value < 5
      engines.push PaymentEngines.find_engine('Credits')
    else
      if parent.using_pagarme?
        engines.push PaymentEngines.find_engine('Pagarme')
      else
        engines = PaymentEngines.engines.inject([]) do |total, item|
          if item.name == 'Credits' && current_user.credits > 0
            total << item
          elsif !item.name.match(/(Credits|Pagarme)/)
            total << item
          end

          total
        end
      end
    end

    @engines ||= engines
  end

  def collection
    if params[:with_state]
      @contributions ||= apply_scopes(end_of_association_chain).available_to_display.order("confirmed_at DESC")
    else
      @contributions ||= apply_scopes(end_of_association_chain).available_to_display.available_to_count.order("confirmed_at DESC")
    end
  end

  def use_catarse_boostrap
    ["new", "create", "edit", "update"].include?(action_name) ? 'juntos_bootstrap' : 'application'
  end

  def project_contribution_url_options
    if CatarseSettings.get_without_cache(:secure_host)
      { protocol: params[:protocol], host: params[:host]}
    else
      {}
    end
  end
end
