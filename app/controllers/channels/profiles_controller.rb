class Channels::ProfilesController < Channels::BaseController
  layout 'juntos_bootstrap'
  inherit_resources
  actions :show, :edit, :update
  custom_actions resource: [:how_it_works, :terms, :privacy, :contacts]
  after_filter :verify_authorized, except: [:how_it_works, :show, :terms, :privacy, :contacts]
  before_action :show_statistics, only: [:show]

  def edit
    authorize resource
    edit!
  end

  def update
    authorize resource
    update!
  end

  def resource
    @profile ||= channel
  end

  def create
    @profile = Channel.new channel_params
    if @profile.save
      CreateMultiCategoriesChannel.new(params[:category_id], @profile).call
      redirect_to :back
    else
      render :new
    end
  end

  private

  def show_statistics
    @channel_statistics = ChannelStatisticsQuery.new(resource)
  end

  def channel_params
    params.require(:channel).permit(:name, :permalink, :recurring, :custom_submit_text, :description, category_id:  [])
  end

end
