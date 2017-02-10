class Attachment < ActiveRecord::Base
  belongs_to :attachmentable, polymorphic: true

  validates_presence_of :url
end
