class Channels::ProfilesController < Channels::BaseController
  layout 'juntos_bootstrap'
  inherit_resources
  actions :show, :edit, :update
  custom_actions resource: [:how_it_works, :terms, :privacy, :contacts]
  after_filter :verify_authorized, except: [:how_it_works, :show, :terms, :privacy, :contacts]
  before_action :show_statistics, only: [:show]

  def show
    if resource.recurring?
      redirect_to channels_about_path if Channel::RecurringChannelFirstTimeChecker.first_time?(current_user)
    end
  end

  def edit
    authorize resource
    edit!
  end

  def update
    authorize resource

    if resource.update(permitted_params)
      flash[:notice] = t('success', scope: 'channels.profiles.update')
      redirect_to channels_profile_path(resource)
    else
      flash[:alert] = resource.errors.full_messages.to_sentence
      render :edit
    end
  end

  private

  def resource
    @profile ||= channel
  end

  def permitted_params
    params.require(:profile).permit(:ga_code, :name, :description, :original_image_url,
                                    :original_email_header_image_url, :main_color,
                                    :secondary_color, :facebook, :website, :how_it_works,
                                    :terms, :contacts)
  end

  def show_statistics
    @channel_statistics = ChannelStatisticsQuery.new(resource)
  end
end
