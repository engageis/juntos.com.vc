require 'rails_helper'

RSpec.describe BankAccountDecorator do
  describe "#bank_name" do
    let(:bank) { create(:bank, name: 'Foo bank') }
    let(:bank_account) { create(:bank_account, bank: bank).decorate }

    subject { bank_account.bank_name }

    it "returns the bank account's bank name" do
      expect(subject).to match 'Foo bank'
    end
  end

  describe "#bank_code" do
    let(:bank) { create(:bank, code: '1010') }
    let(:bank_account) { create(:bank_account, bank: bank).decorate }

    subject { bank_account.bank_code }

    it "returns the bank account's bank code" do
      expect(subject).to match '1010'
    end
  end

  describe "#agency" do
    subject { bank_account.agency }

    context "when the agency has a digit" do
      let(:bank_account) { build(:bank_account, agency: '1111', agency_digit: '11').decorate }

      it "returns the agency number plus the agency digit" do
        expect(subject).to match '1111-11'
      end
    end

    context "when the agency does not have a digit" do
      let(:bank_account) { build(:bank_account, agency: '1111', agency_digit: nil).decorate }

      it "returns the agency number" do
        expect(subject).to match '1111'
      end
    end
  end

  describe "#account" do
    let(:bank_account) { build(:bank_account, account: '2222', account_digit: '22').decorate }

    subject { bank_account.account }

    it "returns the account number plus the account digit" do
      expect(subject).to match '2222-22'
    end
  end
end
