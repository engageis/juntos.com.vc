# coding: utf-8
class ProjectsController < ApplicationController
  after_filter :verify_authorized, except: %i[index video video_embed embed embed_panel about_mobile supported_by_channel]
  inherit_resources
  has_scope :pg_search, :by_category_id, :near_of
  has_scope :recent, :expiring, :failed, :successful, :in_funding, :recommended, :not_expired, type: :boolean

  respond_to :html
  respond_to :json, only: [:index, :show, :update]

  def index
    index! do |format|
      format.html do
        if request.xhr?
          @projects = apply_scopes(Project.without_recurring_and_pepsico_channel.visible.order_status)
            .most_recent_first
            .includes(:project_total, :user, :category)
            .page(params[:page]).per(6)
          return render partial: 'project', collection: @projects, layout: false
        else
          @projects = apply_scopes(Project.without_recurring_and_pepsico_channel)

          @title = t("site.title")

          @recommends = ProjectsForHome.recommends.includes(:project_total)
          @projects_near = Project.with_state('online').near_of(current_user.address_state).order("random()").limit(3).includes(:project_total) if current_user
          @expiring = ProjectsForHome.expiring.where(recommended: false).includes(:project_total)
          @recent   = apply_scopes(Project.without_recurring_and_pepsico_channel).with_state('online').where(recommended: false).order("random()").limit(6).includes(:project_total)
          @featured_partners = SitePartner.featured
          @regular_partners = SitePartner.regular
          @site_partners = @featured_partners + @regular_partners
          @channels = Channel.all.reject { |c| c.permalink == 'gastromotiva' || c.permalink == 'garupa' || c.permalink == 'descontinuado_garupa' }
          @banners = HomeBanner.where.not(image: [nil, '']).order(numeric_order: :asc)
        end
      end
    end
  end

  def new
    @project = Project.new user: current_user, new_record: true
    authorize @project
    @title = t('projects.new.title')
    8.times { @project.project_images.build }
    3.times { @project.project_partners.build }
    @project.rewards.build
    @project.subgoals.build
  end

  def create
    options = {user: current_user}
    options.merge!(channels: [channel]) if channel

    @project = Project.new params[:project].merge(options)
    authorize @project
    session[:new_project] = true
    @project.save

    create! { project_by_slug_path(@project.permalink, anchor: 'basics') }
  end

  def destroy
    authorize resource
    destroy!
  end

  def send_to_analysis
    authorize resource

    if resource.recurring? && !resource.recipient
      flash[:alert] = t('projects.recurring.send_to_analysis_error')
      redirect_to project_by_slug_path(@project.reload.permalink,
                                       anchor: 'basics')
    elsif resource.send_to_analysis
      resource.update_attribute(:referal_link, referal_link) if referal_link.present?

      flash[:notice] = t('projects.send_to_analysis')
      redirect_to project_by_slug_path(@project.permalink)
    else
      flash[:alert] = resource.errors.full_messages.to_sentence
      redirect_to project_by_slug_path(@project.reload.permalink,
                                       anchor: 'dashboard_project')
    end
  end

  def save_recipient
    authorize resource

    respond_to do |format|
      format.js do
        all_bank_account_params = extract_bank_account_params

        if all_bank_account_params.present?
          @worker = HandleProjectRecipientWorker.perform_async(
            @project.id,
            all_bank_account_params
          )
        end
      end
    end
  end

  def update
    authorize resource
    update! do |format|
      format.html do
        if resource.errors.present?
          flash[:alert] = resource.errors.full_messages.to_sentence
        else
          flash[:notice] = t('project.update.success')
        end

        redirect_to project_by_slug_path(@project.reload.permalink, anchor: (params[:anchor] || 'dashboard_project') )
      end
    end
  end

  def show
    @title = resource.name
    authorize @project
    fb_admins_add(resource.user.facebook_id) if resource.user.facebook_id
    @channel = resource.channels.first
    @posts_count = resource.posts.count(:all)
    @post = resource.posts.where(id: params[:project_post_id]).first if params[:project_post_id].present?
    @contributions = @project.contributions.available_to_count
    @pending_contributions = @project.contributions.with_state(:waiting_confirmation)
    @plans = Plan.all if @project.recurring?

    if @channel && @channel.recurring?
      @banks = Bank.order(:code).to_collection
      @recurring_active = RecurringContribution.where({
        project: @project,
        user: current_user
      }).active.any?

      @bank_account = params[:bank_account] || {}

      if @project.recipient
        recipient = FindRemoteRecipient.call(@project.recipient)
        @bank_account = recipient.bank_account
      end
    end

    @color = (channel.present? && channel.main_color) || @project.color
  end

  def video
    project = Project.new(video_url: params[:url])
    render json: project.video.to_json
  rescue VideoInfo::UrlError
    render json: nil
  end

  %w(embed video_embed).each do |method_name|
    define_method method_name do
      @title = resource.name
      render layout: 'embed'
    end
  end

  def about_mobile
    resource
  end

  def embed_panel
    @title = resource.name
    render layout: false
  end

  def supported_by_channel
    render json: channel.projects
  end

  protected

  def permitted_params
    p = params.permit(policy(resource).permitted_attributes)
    if params[:anchor] == 'posts'
      p[:project][:posts_attributes]['0'].merge!({user: current_user})
    end
    p
  end

  def resource
    @project ||= (params[:permalink].present? ? Project.by_permalink(params[:permalink]).first! : Project.find(params[:id])).decorate
  end

  def use_catarse_boostrap
    ["new", "create", "show", "about_mobile"].include?(action_name) ? 'juntos_bootstrap' : 'application'
  end

  def extract_bank_account_params
    expected_keys = [:bank_code, :agencia, :conta, :conta_dv,
                     :document_number, :legal_name]

    bank_account_params = (params[:bank_account] || {}).slice(*expected_keys)

    if all_bank_account_params?(bank_account_params, expected_keys)
      bank_account_params
    end
  end

  def all_bank_account_params?(bank_account_params, expected_params)
    bank_account_params.values.count(&:present?) == expected_params.count
  end
end
