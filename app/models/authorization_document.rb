class AuthorizationDocument < ActiveRecord::Base
  belongs_to :authable, polymorphic: true
  has_one    :attachment, as: :attachmentable

  validates_presence_of :expires_at

  validate :attachment_present

  accepts_nested_attributes_for :attachment

  enum category: [
                  :uncategorized,
                  :bank_authorization,
                  :organization_authorization,
                  :bylaw_registry,
                  :last_general_meeting_minute,
                  :fiscal_council_report,
                  :directory_proof,
                  :last_mandate_balance,
                  :cnpj_card,
                  :certificates,
                  :last_year_activities_report,
                  :organization_current_plan,
                  :federal_tributes_certificate,
                  :federal_court_debt_certificate,
                  :manager_id
                ]

  def uploaded?
    attachment && attachment.url.present?
  end

  protected

  def attachment_present
    assign_document_error(category_i18n) unless uploaded?
  end

  private

  def assign_document_error(doc_category)
    errors.add(:attachment, :without_attachment, category: doc_category)
  end
end
