# coding: utf-8
require 'rails_helper'

RSpec.describe Bank, type: :model do
  describe ".order_popular" do
    subject { Bank.order_popular }
    let(:user_01) { create(:user) }
    let(:bank_01) { create(:bank, name: "Foo") }
    let(:bank_02) { create(:bank, name: "Foo bar", code: "001") }

    before do
      user_01
      bank_01
      bank_02
    end

    context "we have bank accounts" do
      before do
        @bank_account01 = create(:bank_account, user: user_01, bank: bank_01)
        @bank_account02 = create(:bank_account, user: user_01, bank: bank_01)
        @bank_account03 = create(:bank_account, user: user_01, bank: bank_02)
      end

      xit "should return a collection with banks in order of most used" do
        is_expected.to eq([bank_01, bank_02])
      end
    end
  end

  describe '.to_collection' do
    let(:banks) { create_list :bank, 2 }
    let(:collection) { banks.map { |bank| [bank.to_s, bank.id] } }
    subject { Bank.to_collection }

    before do
      allow(Bank).to receive(:order_popular).and_return(banks)
    end

    it { is_expected.to match_array collection }
  end

  describe '#to_s' do
    let(:bank) { build :bank, name: 'Bank', code: '007' }
    let(:result_string) { "#{bank.code} . #{bank.name}" }
    subject { bank.to_s }

    it { is_expected.to eq result_string }
  end
end
