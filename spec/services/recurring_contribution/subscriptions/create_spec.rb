require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::Create do
  include RecurringContributionsHelper

  describe '.process' do
    let(:pagarme_plan) { build_plan_mock(100) }
    let!(:juntos_plan) { create(:plan, plan_code: pagarme_plan.id) }
    let(:recurring_project) { create(:project) }
    let(:user) { create(:user) }

    context "when all parameters are valid" do
      let(:pagarme_api_response) { build_subscription_mock(payment_method, pagarme_plan) }

      before do
        allow_any_instance_of(RecurringContribution::Subscriptions::CreatePagarme)
          .to receive(:process).and_return(pagarme_api_response)
      end

      context "when the payment_method is credit_card" do
        let(:payment_method) { 'credit_card' }
        let(:credit_card_hash) { build(:credit_card) }
        let(:juntos_subscription) { create(:subscription, plan: juntos_plan, project: recurring_project, user: user, payment_method: payment_method) }
        let(:create_subscription_service) do
          RecurringContribution::Subscriptions::Create.process(juntos_subscription, credit_card_hash)
        end

        it "should return an updated juntos' subscription" do
          subscription = create_subscription_service
          expect(subscription.subscription_code).to eq pagarme_api_response.id
        end
      end

      context "when the payment_method is bank_billet" do
        let(:payment_method) { 'bank_billet' }
        let(:juntos_subscription) { create(:subscription, plan: juntos_plan, project: recurring_project, user: user, payment_method: payment_method) }
        let(:create_subscription_service) do
          RecurringContribution::Subscriptions::Create.process(juntos_subscription)
        end

        it "should return an updated juntos' subscription" do
          subscription = create_subscription_service
          expect(subscription.subscription_code).to eq pagarme_api_response.id
        end
      end
    end

    context "when a problem occurs with the pagarme's subscription creation" do
      let(:pagarme_api_response) { nil }
      let(:payment_method) { 'invalid payment_method' }
      let(:juntos_subscription) { create(:subscription, plan: juntos_plan, project: recurring_project, user: user, payment_method: 'bank_billet') }
      let(:create_subscription_service) do
        RecurringContribution::Subscriptions::Create.process(juntos_subscription)
      end

      before do
        allow_any_instance_of(RecurringContribution::Subscriptions::CreatePagarme)
          .to receive(:process).and_raise(Pagarme::API::InvalidAttributeError)
      end

      it "should return a non persisted instance of Subscription model" do
        expect { create_subscription_service }
          .to raise_error(Pagarme::API::InvalidAttributeError)
      end
    end
  end
end
