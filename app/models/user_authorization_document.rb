class UserAuthorizationDocument < AuthorizationDocument
  OPTIONAL_DOCUMENTS = %i(certificates last_year_activities_report organization_current_plan)

  def attachment_present
    assign_document_error(category_i18n) if invalid_document?
  end

  def invalid_document?
    document_required? && attachment.url.blank?
  end

  def document_required?
    OPTIONAL_DOCUMENTS.exclude?(category.to_sym)
  end
end
