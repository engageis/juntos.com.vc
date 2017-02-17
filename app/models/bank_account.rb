class BankAccount < ActiveRecord::Base
  belongs_to :user
  belongs_to :bank
  belongs_to :project
  has_many   :authorization_documents

  validates :bank_id, :agency, :account, :owner_name, :owner_document, :account_digit, presence: true

  accepts_nested_attributes_for :authorization_documents

  scope :by_user, -> (user) { where(user_id: user.id) }

  def self.setup_with_authorization_documents
    bank_account = BankAccount.new

    [:bank_authorization, :organization_authorization].each do |category|
      document = bank_account.authorization_documents.build(category: category)
      document.build_attachment
    end

    bank_account
  end
end
