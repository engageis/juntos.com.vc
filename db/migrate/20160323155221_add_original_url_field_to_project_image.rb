class AddOriginalUrlFieldToProjectImage < ActiveRecord::Migration
  def change
    add_column :project_images, :original_image_url, :string
  end
end
