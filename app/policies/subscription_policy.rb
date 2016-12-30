class SubscriptionPolicy < ApplicationPolicy
  def create?
    done_by_owner_or_admin?
  end

  alias_method :update?, :create?
  alias_method :cancel?, :create?
end
