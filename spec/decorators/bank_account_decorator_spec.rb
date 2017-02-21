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
end
