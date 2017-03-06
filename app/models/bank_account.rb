class BankAccount < ActiveRecord::Base
  belongs_to :user
  belongs_to :bank
  belongs_to :project
  has_many   :authorization_documents, as: :authable

  validates :bank_id, :agency, :account, :owner_name, :owner_document, :account_digit, presence: true

  accepts_nested_attributes_for :authorization_documents

  scope :by_user, -> (user) { where(user_id: user.id) }

  AUTHORIZATION_DOCUMENTS = [:bank_authorization, :organization_authorization]
end
