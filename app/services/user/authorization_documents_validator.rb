class User::AuthorizationDocumentsValidator
  include ActiveModel::Model
  include Virtus.model

  attribute :optional_documents, Array[Symbol],
            default: [:certificates, :last_year_activities_report, :organization_current_plan]
  attribute :user, User

  validate :required_documents_sent

  def save
    return persist! if valid?

    false
  end

  def persisted?
    false
  end

  private

  def persist!
    user.authorization_documents.each do |document|
      next if document.attachment.url.blank?

      document.save
    end

    true
  end

  def required_documents_sent
    assign_documents_error if invalid_document_sent?
  end

  def assign_documents_error
    user.valid?

    user.errors['authorization_documents.attachment'].each do |error|
      errors.add(:authorization_documents, error)
    end
  end

  def invalid_document_sent?
    user.authorization_documents.any? { |document| invalid_document?(document) }
  end

  def invalid_document?(document)
    return false if optional_document?(document)

    document.attachment.url.blank?
  end

  def optional_document?(document)
    document.attachment.url.blank? && optional_documents.include?(document.category.to_sym)
  end
end
