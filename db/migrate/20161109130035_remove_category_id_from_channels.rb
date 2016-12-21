class RemoveCategoryIdFromChannels < ActiveRecord::Migration
  def change
    remove_column :channels, :category_id
  end
end
