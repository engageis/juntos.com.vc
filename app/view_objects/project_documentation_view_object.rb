class ProjectDocumentationViewObject
  attr_reader :bank_account, :banks, :project, :user

  def initialize(banks:, project:)
    @bank_account = build_authorization_documents(
      resource: BankAccount.new,
      documents: BankAccount::AUTHORIZATION_DOCUMENTS
    )

    @user = build_authorization_documents(
      resource: project.user,
      documents: User::LEGAL_ENTITY_AUTHORIZATION_DOCUMENTS
    )

    @banks = banks
    @project = project.decorate
  end

  def associated_bank_account
    project.bank_account
  end

  def user_bank_accounts
    user.bank_accounts.decorate
  end

  def user_authorization_documents
    decorate_documents(user.authorization_documents)
  end

  def user_without_bank_accounts?
    user.bank_accounts.empty?
  end

  def project_id
    project.id
  end

  def project_owner_id
    project.user.id
  end

  private

  def build_authorization_documents(resource:, documents:)
    if resource.authorization_documents.empty?
      documents.each do |category|
        document = resource.authorization_documents.build(category: category)
        document.build_attachment
      end
    end

    resource
  end

  def decorate_documents(documents)
    AuthorizationDocumentDecorator.decorate_collection(documents)
  end
end
