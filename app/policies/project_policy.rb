class ProjectPolicy < ApplicationPolicy

  self::UserScope = Struct.new(:current_user, :user, :scope) do
    def resolve
      if current_user.try(:admin?) || current_user == user
        scope.without_state('deleted')
      else
        scope.without_state(['deleted', 'draft', 'in_analysis', 'rejected'])
      end
    end
  end

  def create?
    done_by_owner_or_admin?
  end

  def update?
    create?
  end

  def send_to_analysis?
    create?
  end

  def save_recipient?
    create?
  end

  def edit_partner?
    is_admin?
  end

  def permitted_attributes
    return project_attributes_for_admin if admin? || not_visible_project?
    return project_attributes_for_owner if visible_and_owned_by_user?
    return basic_project_attributes
  end

  private

  def not_visible_project?
    !record.visible?
  end

  def visible_and_owned_by_user?
    record.visible? && is_owned_by?(user)
  end

  def admin?
    return false unless user.present?

    user.admin? || is_project_channel_admin?
  end

  def project_attributes_for_admin
    { project: project_attributes + project_nested_attributes + post_attributes }
  end

  def project_attributes
    record.attribute_names.map(&:to_sym) - [:created_at, :updated_at]
  end

  def post_attributes
    [posts_attributes: [:title, :comment, :exclusive, :user_id]]
  end

  def project_nested_attributes
    [
      channel_ids: [],
      plan_ids: [],
      project_images_attributes: [:original_image_url, :caption, :id, :_destroy],
      project_partners_attributes: [:original_image_url, :link, :id, :_destroy]
    ]
  end

  def project_attributes_for_owner
    {
      project: [
        :name, :video_url, :about, :thank_you, :uploaded_image,
        :uploaded_cover_image, :headline, :original_uploaded_image,
        :original_uploaded_cover_image,
        project_images_attributes: [:original_image_url, :caption, :id, :_destroy],
        project_partners_attributes: [:original_image_url, :link, :id, :_destroy],
        posts_attributes: [:title, :comment, :exclusive, :user_id]
      ]
    }
  end

  def basic_project_attributes
    { project: [:about, :video_url, :uploaded_image, :headline] }
  end
end
