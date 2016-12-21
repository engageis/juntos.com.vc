class CreateCategoriesChannels < ActiveRecord::Migration
  def change
    create_table :categories_channels do |t|
      t.integer :category_id
      t.integer :channel_id
    end
  end
end
