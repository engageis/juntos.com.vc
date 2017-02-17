class UserDecorator < Draper::Decorator
  delegate_all

  def channel_owner?(channel)
    source.channel == channel
  end

  def contributions_text
    i18n_scope = 'user.contributions_text'

    if source.total_contributed_projects == 1
      I18n.t('one', scope: i18n_scope)
    elsif source.total_contributed_projects == 2
      I18n.t('two', scope: i18n_scope)
    elsif source.total_contributed_projects > 2
      I18n.t('many', scope: i18n_scope, total: (source.total_contributed_projects-1))
    end
  end

  def twitter_link
    "http://twitter.com/#{source.twitter}" unless source.twitter.blank?
  end

  def gravatar_url(size=80)
    return unless source.email
    image_name = Digest::MD5.new.update(source.email)
    base_url = CatarseSettings[:base_url]

    "https://gravatar.com/avatar/#{image_name}.jpg?default=#{base_url}/assets/user.png&s=#{size}"
  end

  def display_name
    source.name.presence || source.full_name.presence || I18n.t('no_name', scope: 'user')
  end

  def display_image
    source.uploaded_image.thumb_avatar.url || source.image_url || gravatar_url || '/user.png'
  end

  def larger_display_image
    source.uploaded_image.larger_thumb_avatar.url || source.image_url || gravatar_url(256) || '/user.png'
  end

  def display_image_html(options={width: 119, height: 121})
    div_style = "width: #{options[:width]}px; height: #{options[:height]}px"
    image_style = "width: #{options[:width]}px; height: auto"

    h.content_tag :div, class: "avatar_wrapper", style: div_style do
      h.image_tag(display_image, alt: "User", style: image_style)
    end
  end

  def short_name
    h.truncate display_name, length: 20
  end

  def medium_name
    h.truncate display_name, length: 42
  end

  def display_credits
    h.number_to_currency source.credits
  end

  def display_total_of_contributions
    h.number_to_currency source.contributions.with_state('confirmed').sum(:value)
  end

  def display_requested_refund_contributions_count
    source.contributions.with_state('requested_refund').count
  end

  def projects_count
    source.projects.with_state(["online", "waiting_funds", "successful", "failed"]).count
  end

  def display_pending_documents
    user_documents_div if source.pending_documents?
  end

  def display_project_not_approved
    user_documents_div unless source.approved?
  end

  def following_this_category?(category_id)
    source.category_followers.pluck(:category_id).include?(category_id)
  end

  def display_unsuccessful_project_count
    source.failed_contributed_projects.count
  end

  def display_last_unsuccessful_project_expires_at
    source.failed_contributed_projects.last.try(:expires_at).to_i
  end

  def to_json
    to_analytics_json
  end

  def to_analytics_json
    {
      id: source.id,
      email: source.email,
      total_contributed_projects: source.total_contributed_projects,
      total_created_projects: source.projects.count,
      created_at: source.created_at,
      last_sign_in_at: source.last_sign_in_at,
      sign_in_count: source.sign_in_count,
      created_today: source.created_today?
    }.to_json
  end

  def to_param
    return "#{source.id}" unless display_name != I18n.t('no_name', scope: 'user')
    "#{source.id}-#{display_name.parameterize}"
  end

  def display_user_projects_link(font_smaller=false)
    display_projects_link(font_smaller) if source.projects.present?
  end

  def project_owner?
    source.projects.present?
  end

  private

  def user_documents_div
    url = h.user_path(h.current_user, anchor: 'settings')
    css_classes = [
      "fontsize-smaller",
      "fontweight-light",
      "u-marginbottom-30",
      "u-radius",
      "card",
      "card-message"
    ]
    text = I18n.t('user_documents_html', url: url, scope: 'projects.show')

    h.content_tag(:div, text, class: css_classes)
  end

  def display_projects_link(font_smaller=false)
    url = h.user_path(h.current_user, anchor: 'projects')

    css_class = if font_smaller
                  [
                    "w-dropdown-link",
                    "dropdown-link",
                    "fontsize-smaller"
                  ]
                end

    h.content_tag :div, class: css_class do
      h.link_to(I18n.t('projects', scope: 'shared.header'), url)
    end
  end
end
