class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.string :url
      t.string :type
      t.references :attachmentable, polymorphic: true, index: true

      t.timestamps
    end
  end
end
