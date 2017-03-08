# coding: utf-8
class UsersController < ApplicationController
  after_filter :verify_authorized, except: %i[reactivate]
  inherit_resources
  defaults finder: :find_first_active
  actions :show, :update, :update_password, :unsubscribe_notifications, :credits, :destroy
  respond_to :json, only: [:contributions, :projects, :update]

  before_action :update_staffs, only: :update

  def destroy
    authorize resource
    resource.deactivate
    sign_out(current_user) if current_user == resource
    flash[:notice] = t('users.current_user_fields.deactivate_notice', name: resource.name)
    redirect_to root_path
  end

  def unsubscribe_notifications
    authorize resource
    redirect_to user_path(current_user, anchor: 'unsubscribes')
  end

  def credits
    authorize resource
    redirect_to user_path(current_user, anchor: 'credits')
  end

  def show
    authorize resource
    @user = @user.decorate
    show!{
      fb_admins_add(@user.facebook_id) if @user.facebook_id
      @title = "#{@user.display_name}"
      @credits = @user.contributions.can_refund
      @subscribed_to_posts = @user.posts_subscription
      @unsubscribes = @user.project_unsubscribes
      @credit_cards = @user.credit_cards
      @projects = projects
    }
  end

  def approve
    @user = User.find(params[:id]).decorate
    authorize @user
    @user.update_attribute(:approved_at, Time.now)
    @user.save
    redirect_to user_path(@user)
  end

  def reactivate
    user = params[:token].present? && User.find_by(reactivate_token: params[:token])
    if user
      user.reactivate
      sign_in user
      flash[:notice] = t('users.reactivated')
    else
      flash[:error] = t('users.failed_reactivation')
    end
    redirect_to root_path
  end

  def update
    authorize resource

    @user_update = User::Update.new(user: resource, params: permitted_params[:user])

    respond_to do |format|
      if @user_update.process
        format.json { head :no_content }
        format.html do
          flash[:notice] = t('users.current_user_fields.updated')
          redirect_to user_path(@user_update.resource, anchor: 'settings')
        end
      else
        format.json { render json: { errors: @user_update.resource.errors.full_messages.to_sentence }, status: :bad_request }
        format.html do
          flash[:error] = @user_update.resource.errors.full_messages.to_sentence
          redirect_to user_path(@user_update.resource, anchor: 'settings')
        end
      end
    end
  end

  def update_password
    authorize resource
    if @user.update_with_password(permitted_password_params)
      flash[:notice] = t('users.current_user_fields.updated')
    else
      flash[:error] = @user.errors.full_messages.to_sentence
    end
    return redirect_to user_path(@user, anchor: 'settings')
  end

  protected

  def policy_scope(scope)
    @_policy_scoped = true
    ProjectPolicy::UserScope.new(current_user, resource, scope).resolve
  end

  def projects
    @projects ||= policy_scope(resource.projects)
  end

  private

  def permitted_params
    params.permit(policy(resource).permitted_attributes)
  end

  def permitted_password_params
    params[:user].permit(:current_password, :password, :password_confirmation)
  end

  def update_staffs
    unless params[:user].blank? || params[:user][:staffs].blank?
      params[:user][:staffs] = params[:user][:staffs].reject(&:blank?)
    end
  end
end
