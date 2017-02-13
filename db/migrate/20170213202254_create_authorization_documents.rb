class CreateAuthorizationDocuments < ActiveRecord::Migration
  def change
    create_table :authorization_documents do |t|
      t.datetime :expires_at
      t.references :bank_account, index: true

      t.timestamps
    end
  end
end
