require 'rails_helper'

RSpec.describe RecurringContribution::JuntosSubscription do
  include RecurringContributionsHelper

  describe '#process' do
    let(:project) { create(:project) }
    let(:plan) { create(:plan) }
    let(:user) { create(:user) }
    let(:juntos_subscription_service) { RecurringContribution::JuntosSubscription.new(project, plan, user, 'credit_card') }

    context 'when the models subscription and transaction are successfully created' do
      let(:pagarme_subscription) { build_subscription_mock('credit_card') }
      let(:juntos_subscription)  { juntos_subscription_service.process(pagarme_subscription) }

      it 'must create a subscription model' do
        expect(juntos_subscription.subscription_code).to eq(pagarme_subscription.id)
      end

      it 'must create a transaction model' do
        juntos_transaction = juntos_subscription.transactions.first
        pagarme_transaction = pagarme_subscription.current_transaction
        expect(juntos_transaction.transaction_code).to eq(pagarme_transaction.id)
      end
    end

    context 'when a problem occurs on creation of models subscription and transaction' do
      let(:invalid_pagarme_subscription) { build_subscription_mock('invalid_payment_method') }
      let(:invalid_juntos_subscription)  { juntos_subscription_service.process(invalid_pagarme_subscription) }

      it 'should not create a subscription model' do
        expect(Subscription.count).to eq(0)
      end

      it 'should not create a transaction model' do
        expect(Transaction.count).to eq(0)
      end
    end
  end
end
