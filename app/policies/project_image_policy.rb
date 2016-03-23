class ProjectImagePolicy < ApplicationPolicy

  self::Scope = Struct.new(:user, :scope) do

    def resolve
      scope
    end

  end

  def create?
    done_by_owner_or_admin?
  end

  def update?
    done_by_owner_or_admin?
  end

  def destroy?
    done_by_owner_or_admin?
  end

  def permitted_attributes
    if done_by_owner_or_admin?
      { project_image: [:original_image_url, :caption] }
    else
      { project_image: [] }
    end
  end

  protected

  def done_by_owner_or_admin?
    record.project.user == user || user.try(:admin?)
  end
end

