require 'rails_helper'

RSpec.describe Users::BankAccountsController, type: :controller do
  describe "GET index" do
    context "when there is a looged user" do
      context "and the user is an admin" do
        let(:user) { create(:user, admin: true) }

        it "returns a success response code" do
          sign_in user
          get :index, { user_id: user.id, locale: 'pt' }
          expect(response).to be_success
        end
      end

      context "and the user is the owner of the bank accounts" do
        let(:user) { create(:user) }

        before do
          create_list(:bank_account, 2, user: user)
        end

        it "returns a success response code" do
          sign_in user
          get :index, { user_id: user.id, locale: 'pt' }
          expect(response).to be_success
        end
      end
    end

    context "when no user is logged in" do
      let(:user) { create(:user) }

      it "redirects to the application root path" do
        get :index, { user_id: user.id, locale: 'pt' }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET new" do
    context "when user is a guest" do
      let(:user) { create(:user) }

      it "redirects to login path" do
        get :new, { user_id: user.id, locale: 'pt' }
        expect(response).to redirect_to(new_user_registration_path)
      end
    end

    context "when user is a registered user" do
      let(:user) { create(:user, admin: false) }

      it "returns a success response code" do
        sign_in user
        get :new, { user_id: user.id, locale: 'pt' }
        expect(response).to be_success
      end
    end
  end

  describe "POST create" do
    context "when user is a guest" do
      let(:user) { create(:user) }

      it "redirects to login path" do
        post :create, { user_id: user.id, locale: 'pt' }
        expect(response).to redirect_to(new_user_registration_path)
      end
    end

    context "when user is a registered user" do
      let(:user) { create(:user) }

      before do
        sign_in user
        post :create, { user_id: user.id, locale: 'pt', bank_account: params }
      end

      context "and all parameters sent are valid" do
        let(:bank) { create(:bank) }
        let(:created_bank_account) { BankAccount.first }
        let(:params) do
          attributes_for(:bank_account).merge(
            {
              authorization_documents_attributes: [
                expires_at: DateTime.now,
                attachment_attributes: {
                  url: 'www.foo.com/asset',
                  file_type: 'pdf'
                }
              ],
              bank_id: bank.id
            }
          )
        end

        it "returns a json with the persisted bank account" do
          json_response = JSON.parse(response.body)
          expect(json_response['id']).to eq created_bank_account.id
        end
      end

      context "and invalid parameters were sent" do
        let(:params) { attributes_for(:bank_account) }
        let(:error_message) do
          I18n.t('activerecord.attributes.bank_account.bank') + ' ' + \
          I18n.t('activerecord.errors.messages.blank')
        end

        it "returns a json with the error message" do
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to match error_message
        end
      end
    end
  end

  describe "PUT update" do
    let(:user) { create(:user) }
    let(:bank_account) { create(:bank_account, user: user) }

    context "when the user is a guest" do
      it "redirects to login path" do
        put :update, { user_id: user.id, id: bank_account.id, locale: 'pt' }
        expect(response).to redirect_to(new_user_registration_path)
      end
    end

    context "when the user is logged in" do
      before do
        sign_in user
        put :update, { user_id: user.id, id: bank_account.id, bank_account: params, locale: 'pt' }
      end

      context "and all update params are valid" do
        let(:project) { create(:project) }
        let(:params)  { { project_id: project.id } }
        let(:updated_bank_account) { bank_account.reload }

        it "returns the 204 HTTP status" do
          expect(response.code).to eq '204'
        end

        it "updates the bank account resource" do
          expect(updated_bank_account.project_id).to eq project.id
        end
      end

      context "and invalid update params were sent" do
        let(:params) { { bank_id: '' } }

        let(:error_message) do
          I18n.t('activerecord.attributes.bank_account.bank') + ' ' + \
          I18n.t('activerecord.errors.messages.blank')
        end

        it "returns a json with the error message" do
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to match error_message
        end
      end
    end
  end
end
