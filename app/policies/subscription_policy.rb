class SubscriptionPolicy < ApplicationPolicy
  CARD_PERMITTED_PARAMS = [:card_hash]
  SUBSCRIPTION_PERMITTED_PARAMS = [
    :plan_id,
    :project_id,
    :user_id,
    :payment_method,
    :charging_day,
    :charges,
    :donator_cpf
  ]

  def create?
    done_by_owner_or_admin?
  end

  def permitted_attributes
    done_by_owner_or_admin? ? SUBSCRIPTION_PERMITTED_PARAMS : []
  end

  def credit_card_permitted_attributes
    done_by_owner_or_admin? ? CARD_PERMITTED_PARAMS : []
  end

  alias_method :update?, :create?
  alias_method :cancel?, :create?
end
