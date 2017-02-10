require 'rails_helper'

RSpec.describe BankAccountPolicy do
  subject { BankAccountPolicy }
  let(:bank_account) { create(:bank_account) }

  permissions :index? do
    it_behaves_like "create permissions" do
      let(:resource) { bank_account }
    end
  end

  permissions :new? do
    it_behaves_like "create permissions" do
      let(:resource) { bank_account }
    end
  end

  permissions :create? do
    it_behaves_like "create permissions" do
      let(:resource) { bank_account }
    end
  end

  describe ".permitted_attributes" do
    subject { BankAccountPolicy.new(user, resource).permitted_attributes }

    it_behaves_like "resource permitted attributes method" do
      let(:resource_name) { :bank_account }

      let(:permitted_attributes) do
        [
          :bank_id,
          :agency,
          :account,
          :owner_name,
          :owner_document,
          :account_digit,
          authorization_documents_attributes: [
            :expires_at,
            attachment_attributes: [ :url, :file_type ]
          ]
        ]
      end
    end
  end

  describe ".has_list_permission?" do
    subject { BankAccountPolicy.new(user, BankAccount.new).has_list_permission?(bank_accounts) }

    context "when user" do
      context "is admin" do
        let(:user) { create(:user, admin: true) }
        let(:bank_accounts) do
          []
        end

        it "returns true" do
          expect(subject).to eq true
        end
      end

      context "is the owner of all bank accounts" do
        let(:user) { create(:user) }
        let(:bank_accounts) do
          create_list(:bank_account, 3, user: user)
        end

        it "returns true" do
          expect(subject).to eq true
        end
      end

      context "is not the owner of all bank accounts" do
        let(:user) { create(:user) }
        let(:bank_accounts) do
          [ create(:bank_account) ]
        end

        it "returns false" do
          expect(subject).to eq false
        end
      end
    end

    context "when the bank accounts list passed as param is empty and user is not an admin" do
      let(:user) { create(:user) }
      let(:bank_accounts) do
        []
      end

      it "returns false" do
        expect(subject).to eq false
      end
    end
  end
end
