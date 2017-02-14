class AuthorizationDocument < ActiveRecord::Base
  belongs_to :bank_account
  has_one    :attachment, as: :attachmentable

  validates_presence_of :expires_at

  accepts_nested_attributes_for :attachment
end
