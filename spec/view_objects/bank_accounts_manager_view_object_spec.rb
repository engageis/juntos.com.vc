require 'rails_helper'

RSpec.describe BankAccountsManagerViewObject do
  describe "attributes" do
    let(:project) { build(:project) }
    let(:banks) { [build(:bank), build(:bank)] }

    subject { described_class.new(project: project, banks: banks) }

    it { is_expected.to respond_to(:bank_account) }
    it { is_expected.to respond_to(:banks) }
    it { is_expected.to respond_to(:project) }
    it { is_expected.to respond_to(:user) }
  end

  describe "#user_bank_accounts" do
    let(:project) { build(:project, user: user) }
    let(:bank_accounts_manager) { described_class.new(project: project, banks: []) }

    subject { bank_accounts_manager.user_bank_accounts }

    context "when the user has bank accounts" do
      let(:bank) { create(:bank) }
      let(:bank_account) { create(:bank_account, bank: bank) }
      let(:user) { create(:user, bank_accounts: [bank_account]) }

      it "returns the accounts with the decorated methods" do
        expect(subject.first).to respond_to(:bank_name, :bank_code)
      end
    end

    context "when the user does not have bank accounts" do
      let(:user) { build(:user, bank_accounts: []) }

      it "returns an empty list" do
        expect(subject).to be_empty
      end
    end
  end

  describe "#user_without_bank_accounts?" do
    let(:project) { build(:project, user: user) }
    let(:bank_accounts_manager) { described_class.new(project: project, banks: []) }

    subject { bank_accounts_manager.user_without_bank_accounts? }

    context "when the user has bank accounts" do
      let(:user) { build(:user, bank_accounts: [ build(:bank_account) ]) }

      it "returns false" do
        expect(subject).to eq false
      end
    end

    context "when the user does not have bank accounts" do
      let(:user) { build(:user, bank_accounts: []) }

      it "returns true" do
        expect(subject).to eq true
      end
    end
  end

  describe "#project_id" do
    let(:project) { double('Project', id: 10, user: build(:user)) }
    let(:bank_accounts_manager) { described_class.new(project: project, banks: []) }

    subject { bank_accounts_manager.project_id }

    it "returns the project id" do
      expect(subject).to eq 10
    end
  end
end
