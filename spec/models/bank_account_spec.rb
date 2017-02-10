require 'rails_helper'

RSpec.describe BankAccount, type: :model do
  describe "associations" do
    it { is_expected.to belong_to :user }
    it { is_expected.to belong_to :bank }
    it { is_expected.to have_many :authorization_documents }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:bank_id) }
    it { is_expected.to validate_presence_of(:agency) }
    it { is_expected.to validate_presence_of(:account) }
    it { is_expected.to validate_presence_of(:account_digit) }
    it { is_expected.to validate_presence_of(:owner_name) }
    it { is_expected.to validate_presence_of(:owner_document) }
  end

  describe "scopes" do
    describe ".by_user" do
      let(:user) { create(:user) }
      let(:user_bank_accounts) { create_list(:bank_account, 2, user: user) }

      before do
        create_list(:bank_account, 4)
      end

      subject { BankAccount.by_user(user) }

      it "returns only the user's bank accounts" do
        expect(subject).to match_array user_bank_accounts
      end
    end
  end
end
