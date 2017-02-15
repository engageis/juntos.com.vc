class AddDescriptionToAuthorizationDocuments < ActiveRecord::Migration
  def change
    add_column :authorization_documents, :category, :integer, default: 0
  end
end
