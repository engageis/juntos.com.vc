class ChangeAttachmentsTypeColumnName < ActiveRecord::Migration
  def change
    rename_column :attachments, :type, :file_type
  end
end
