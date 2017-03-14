class SubscriptionReport < ActiveRecord::Base
  belongs_to :project

  mount_uploader :attachment, DocumentUploader
end
