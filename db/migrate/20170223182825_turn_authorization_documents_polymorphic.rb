class TurnAuthorizationDocumentsPolymorphic < ActiveRecord::Migration
  def change
    remove_column :authorization_documents, :bank_account_id, :integer
    add_reference :authorization_documents, :authable, polymorphic: true, index: true
  end
end
