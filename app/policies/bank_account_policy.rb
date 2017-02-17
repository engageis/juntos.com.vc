class BankAccountPolicy < ApplicationPolicy
  PERMITTED_PARAMS = [
    :bank_id,
    :project_id,
    :agency,
    :agency_digit,
    :account,
    :owner_name,
    :owner_document,
    :account_digit,
    authorization_documents_attributes: [
      :expires_at,
      attachment_attributes: [ :url, :file_type ]
    ]
  ]

  def create?
    done_by_owner_or_admin?
  end

  def update?
    done_by_owner_or_admin?
  end

  def has_list_permission?(bank_accounts)
    return true if admin_user?

    user_owns_all_bank_accounts?(bank_accounts)
  end

  def permitted_attributes
    done_by_owner_or_admin? ? PERMITTED_PARAMS : []
  end

  alias_method :new?, :create?
  alias_method :index?, :create?

  private

  def admin_user?
    user.present? && user.admin?
  end

  def user_owns_all_bank_accounts?(bank_accounts)
    bank_accounts.present? && bank_accounts.all? { |b| b.user == user }
  end
end
