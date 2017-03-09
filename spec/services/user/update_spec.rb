require 'rails_helper'

RSpec.describe User::Update do
  describe ".process" do
    let(:user) { create(:user) }
    let(:user_update_service) { described_class.new(user: user, params: params) }

    subject { user_update_service.process }

    context "when the attributes for authorization documents were passed as param" do
      let(:attachment_url) { '' }
      let(:params) do
        {
          authorization_documents_attributes: {
            "0" => {
              expires_at: Date.current,
              category: :cnpj_card,
              attachment_attributes: {
                url: attachment_url
              }
            }
          }
        }
      end

      it "assigns the resource attribute with a User::AuthorizationDocumentsValidator instance" do
        user_update_service.process
        expect(user_update_service.resource).to be_a(User::AuthorizationDocumentsValidator)
      end

      context "and all attributes are valid" do
        let(:attachment_url) { 'http://valid.url.com' }

        it "returns true" do
          expect(subject).to eq true
        end

        it "updates the authorization documents" do
          user_update_service.process
          new_authorization_document = user.authorization_documents.first
          expect(new_authorization_document.attachment.url).to eq 'http://valid.url.com'
        end
      end

      context "and a invalid attribute is sent" do
        let(:attachment_url) { '' }

        it "does not update the authorization documents" do
          expect(subject).to eq false
        end
      end
    end

    context "when the params do not have the authorization documents attributes" do
      let(:params) { { email: 'valid_email@foo.com' } }

      it "assigns the resource attribute with a User instance" do
        user_update_service.process
        expect(user_update_service.resource).to be_a(User)
      end

      context "and all attributes are valid" do
        it "returns true" do
          expect(subject).to eq true
        end

        it "updates the user" do
          user_update_service.process
          expect(user.email).to match 'valid_email@foo.com'
        end
      end

      context "and a invalid attribute is sent" do
        let(:params) { { email: '' } }

        it "does not update the user" do
          expect(subject).to eq false
        end
      end
    end
  end
end
