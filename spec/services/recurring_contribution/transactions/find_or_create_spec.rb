require 'rails_helper'

RSpec.describe RecurringContribution::Transactions::FindOrCreate do
  describe ".process" do
    subject { described_class.process(transaction_code) }

    context "when the transaction is found" do
      let(:transaction)      { create(:transaction) }
      let(:transaction_code) { transaction.transaction_code }

      it { is_expected.to eq(transaction) }
    end

    context "when the transaction is not found" do
      let(:transaction_code)    { 1000 }
      let(:subscription)        { create(:subscription) }
      let(:transaction)         { build_transaction_mock(subscription.subscription_code) }
      let(:created_transaction) { Transaction.find_by(transaction_code: transaction.id) }

      before do
        allow(Pagarme::API).to receive(:find_transaction).and_return(transaction)
      end

      it { is_expected.to eq(created_transaction) }

      it "should have called the Transaction create method" do
        expect(Transaction).to receive(:create).once.and_return(created_transaction)

        subject
      end
    end
  end
end
