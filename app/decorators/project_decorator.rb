class ProjectDecorator < Draper::Decorator
  delegate_all
  decorates_association :bank_account
  include Draper::LazyHelpers

  def remaining_text
    pluralize_without_number(source.time_to_go[:time], I18n.t('remaining_singular'), I18n.t('remaining_plural'))
  end

  def state_warning_template
    "#{source.state}_warning"
  end

  def new_contribution_link
    object.recurring? ? new_project_subscription_path(object) : new_project_contribution_path(object)
  end

  def standard_plan_id
    plan = object.plans.first
    plan ? plan.id : nil
  end

  def time_to_go
    time_and_unit = nil
    %w(day hour minute second).detect do |unit|
      time_and_unit = time_to_go_for unit
    end
    time_and_unit || time_and_unit_attributes(0, 'second')
  end

  def remaining_days
    source.time_to_go[:time]
  end

  def display_card_class
    default_card = "card u-radius zindex-10"
    aditional = ""
    if source.waiting_funds?
      aditional = 'card-waiting'
    elsif source.successful?
      aditional = 'card-success'
    elsif source.failed?
      aditional = 'card-error'
    elsif source.draft? || source.in_analysis?
      aditional = 'card-dark'
    else
      default_card = ""
    end
    "#{default_card} #{aditional}"
  end

  def display_status
    if source.online?
      (source.reached_goal? ? 'reached_goal' : 'not_reached_goal')
    else
      source.state
    end
  end

  # Method for width of progress bars only
  def display_progress
    return 100 if source.successful? || source.progress > 100
    return 8 if source.progress > 0 and source.progress < 8
    source.progress
  end

  def display_image(version = 'project_thumb' )
    use_uploaded_image(version) || use_video_tumbnail(version)
  end

  def display_expires_at
    source.expires_at ? I18n.l(source.expires_at.try(:in_time_zone,Rails.application.config.time_zone).to_date) : ''
  end

  def display_online_date
    source.online_date ? I18n.l(source.online_date.to_date) : ''
  end

  def progress(divisor = 1)
    return 0 if source.goal == 0.0 || source.goal.nil?
    ((source.pledged / (source.goal / divisor)) * 100).to_i
  end

  def display_pledged(multiply = 1)
    number_to_currency (source.pledged * multiply)
  end

  def display_goal
    number_to_currency source.goal
  end

  def display_subgoals
    source.subgoals.where("value <= ?", source.goal)
  end

  def display_id
    "##{source.id}"
  end

  def progress_bar
    width = source.progress > 100 ? 100 : source.progress
    content_tag(:div, nil, id: :progress, class: 'meter-fill', style: "width: #{width}%;")
  end


  def status_flag
    content_tag(:div, class: [:status_flag]) do
      if source.successful?
        image_tag "successful.#{I18n.locale}.png"
      elsif source.failed?
        image_tag "not_successful.#{I18n.locale}.png"
      elsif source.waiting_funds?
        image_tag "waiting_confirmation.#{I18n.locale}.png"
      end
    end

  end

  def category_image_url
    if source.category.image.present?
      source.category.image.url
    else
      'juntos/icone_placeholder.png'
    end
  end

  def partner_display_message
    if source.partner_message.present?
      source.partner_message
    else
      I18n.t('projects.partner_message', partner: source.partner_name)
    end
  end

  def editable_field?
    source.visible? && source.user == current_user
  end

  private

  def use_uploaded_image(version)
    source.uploaded_image.send(version).url if source.uploaded_image.present?
  end

  def use_video_tumbnail(version)
    if source.video_thumbnail.url.present?
      source.video_thumbnail.send(version).url
    elsif source.video
      source.video.thumbnail_large
    end
  rescue
    nil
  end

  def time_to_go_for(unit)
    time = 1.send(unit)

    if source.expires_at.to_i >= time.from_now.to_i
      time = ((source.expires_at - Time.zone.now).abs / time).floor
      time_and_unit_attributes time, unit
    end
  end

  def time_and_unit_attributes(time, unit)
    { time: time, unit: pluralize_without_number(time, I18n.t("datetime.prompts.#{unit}").downcase) }
  end
end
