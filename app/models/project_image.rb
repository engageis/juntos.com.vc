class ProjectImage < ActiveRecord::Base
  belongs_to :project
  mount_uploader :image, ProjectUploader

  validates :original_image_url, presence: true
end
