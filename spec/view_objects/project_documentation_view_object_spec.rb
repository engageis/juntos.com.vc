require 'rails_helper'

RSpec.describe ProjectDocumentationViewObject do
  describe "attributes" do
    let(:project) { build(:project) }
    let(:banks) { [build(:bank), build(:bank)] }

    subject { described_class.new(project: project, banks: banks) }

    it { is_expected.to respond_to(:bank_account) }
    it { is_expected.to respond_to(:banks) }
    it { is_expected.to respond_to(:project) }
    it { is_expected.to respond_to(:user) }

    describe "authorization documents" do
      let(:resource_documents) { authorization_documents.map { |doc| doc.category.to_sym } }

      context "when the resource is a bank account" do
        let(:authorization_documents) { subject.bank_account.authorization_documents }

        it "builds all the bank account's required authorization_documents" do
          expect(resource_documents).to match_array BankAccount::AUTHORIZATION_DOCUMENTS
        end
      end

      context "when the resource is an user" do
        let(:authorization_documents) { subject.user.authorization_documents }

        it "builds all the user's required authorization_documents" do
          expect(resource_documents).to match_array User::LEGAL_ENTITY_AUTHORIZATION_DOCUMENTS
        end
      end
    end
  end

  describe ".user_bank_accounts" do
    let(:project) { build(:project, user: user) }
    let(:project_documentation) { described_class.new(project: project, banks: []) }

    subject { project_documentation.user_bank_accounts }

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

  describe ".user_authorization_documents" do
    let(:user) { create(:user) }
    let(:project) { build(:project, user: user) }
    let(:project_documentation) { described_class.new(project: project, banks: []) }

    subject { project_documentation.user_authorization_documents }

    it "returns a list with all the user's authorization_documents" do
      categories = subject.map { |doc| doc.category.to_sym }
      expect(categories).to match_array User::LEGAL_ENTITY_AUTHORIZATION_DOCUMENTS
    end
  end

  describe ".user_without_bank_accounts?" do
    let(:project) { build(:project, user: user) }
    let(:project_documentation) { described_class.new(project: project, banks: []) }

    subject { project_documentation.user_without_bank_accounts? }

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

  describe ".project" do
    let(:user) { build(:user) }
    let(:project) { build(:project, user: user) }
    let(:project_documentation) { described_class.new(project: project, banks: []) }

    subject { project_documentation.project }

    it { is_expected.to be_decorated }
  end

  describe ".project_id" do
    let(:project) { double('Project', id: 10, user: build(:user)) }
    let(:project_documentation) { described_class.new(project: project, banks: []) }

    before { allow(project).to receive(:decorate).and_return(project) }

    subject { project_documentation.project_id }

    it "returns the project id" do
      expect(subject).to eq 10
    end
  end

  describe ".project_owner_id" do
    let(:user) { create(:user) }
    let(:project) { build(:project, user: user) }
    let(:project_documentation) { described_class.new(project: project, banks: []) }

    subject { project_documentation.project_owner_id }

    it { is_expected.to eq user.id }
  end

  describe ".associated_bank_account" do
    let(:bank_account) { build(:bank_account) }
    let(:project) { create(:project, bank_account: bank_account) }
    let(:project_documentation) { described_class.new(project: project, banks: []) }

    subject { project_documentation.associated_bank_account }

    it "returns the project's bank account" do
      expect(subject).to eq bank_account
    end
  end
end
