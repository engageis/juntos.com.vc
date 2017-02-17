class BankAccountsManagerViewObject
  attr_reader :bank_account, :banks, :project, :user

  def initialize(banks:, project:)
    @bank_account = BankAccount.setup_with_authorization_documents
    @banks = banks
    @project = project
    @user = project.user
  end

  def user_bank_accounts
    user.bank_accounts.decorate
  end

  def user_without_bank_accounts?
    user.bank_accounts.empty?
  end

  def project_id
    project.id
  end
end
