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

        it "returns a success flash message" do
          expect(flash[:notice]).to match I18n.t(:success, scope: 'user.bank_account.create')
        end
      end

      context "and invalid parameters were sent" do
        let(:params) { attributes_for(:bank_account) }
        let(:error_message) do
          I18n.t('activerecord.attributes.bank_account.bank') + ' ' + \
          I18n.t('activerecord.errors.messages.blank')
        end

        it "returns an error flash message" do
          expect(flash[:alert]).to match error_message
        end
      end
    end
  end
end
