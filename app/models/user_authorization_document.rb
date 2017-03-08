class UserAuthorizationDocument < AuthorizationDocument
  OPTIONAL_DOCUMENTS = [
    :certificates,
    :last_year_activities_report,
    :organization_current_plan
  ]

  def attachment_present
    assign_document_error(category_i18n) if invalid_document?
  end

  def invalid_document?
    return false if optional_document?

    attachment.url.blank?
  end

  def optional_document?
    attachment.url.blank? && OPTIONAL_DOCUMENTS.include?(category.to_sym)
  end
end
