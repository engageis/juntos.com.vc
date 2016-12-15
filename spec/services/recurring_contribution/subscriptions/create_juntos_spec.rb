require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::CreateJuntos do
  include RecurringContributionsHelper

  describe '#process' do
    let(:pagarme_plan) { create(:plan) }
    let!(:juntos_plan) { create(:plan, plan_code: pagarme_plan.id) }
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:pagarme_subscription) { build_subscription_mock('credit_card', pagarme_plan) }

    context 'when all the parameters sent to models are valid' do
      let(:juntos_subscription_data) {
         RecurringContribution::Subscriptions::JuntosSubscriptionData.new(user, 'credit_card', pagarme_subscription)
      }
      let(:juntos_subscription_service) {
        RecurringContribution::Subscriptions::CreateJuntos.new(project, juntos_subscription_data)
      }
      let(:juntos_subscription) { juntos_subscription_service.process }
      let(:juntos_transaction) { juntos_subscription.transactions.first }

      it 'should create a subscription model' do
        expect(juntos_subscription.id).to_not be_nil
      end

      it 'should create a transaction model' do
        expect(juntos_transaction.id).to_not be_nil
      end

      it "should create a subscription model with subscription_code equal to pagarme's subscription id" do
        expect(juntos_subscription.subscription_code).to eq(pagarme_subscription.id)
      end

      it "should create a transaction model with transaction_code equal to pagarme's transaction id" do
        expect(juntos_transaction.transaction_code).to eq(pagarme_subscription.current_transaction.id)
      end
    end

    context 'when a invalid parameter is sent' do
      let(:juntos_subscription_data) {
         RecurringContribution::Subscriptions::JuntosSubscriptionData.new(user, 'invalid_payment_method', pagarme_subscription)
      }
      let(:juntos_subscription_service) {
        RecurringContribution::Subscriptions::CreateJuntos.new(project, juntos_subscription_data)
      }
      let(:service_response) { juntos_subscription_service.process }

      it 'should not create the subscription and its transaction' do
        expect(service_response.persisted?).to be_falsy
      end
    end
  end
end
