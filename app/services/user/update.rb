class User::Update
  attr_reader :resource, :params

  def initialize(user:, params:)
    @user = user
    @params = params
  end

  def process
    @user.attributes = params

    if authorization_documents_update?
      @resource = user_authorization_documents_form
      resource.save
    else
      @resource = @user
      resource.save
    end
  end

  private

  def authorization_documents_update?
    params.has_key?(:authorization_documents_attributes)
  end

  def user_authorization_documents_form
    User::AuthorizationDocumentsValidator.new(user: @user, authorization_documents: @user.authorization_documents)
  end
end
