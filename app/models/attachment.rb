class Attachment < ActiveRecord::Base
  belongs_to :attachmentable, polymorphic: true
end
