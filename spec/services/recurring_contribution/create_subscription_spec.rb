require 'rails_helper'

RSpec.describe RecurringContribution::CreateSubscription do
  include RecurringContributionsHelper

  describe '.process' do
    let(:pagarme_plan) { build_plan_mock(100) }
    let!(:juntos_plan) { create(:plan, plan_code: pagarme_plan.id) }
    let(:recurring_project) { create(:project) }
    let(:user) { create(:user) }
    let(:pagarme_api_response) { build_subscription_mock(payment_method, pagarme_plan) }
    let(:pagarme_subscription_service_response) do
      RecurringContribution::Subscriptions::JuntosSubscriptionData.new(user, payment_method, pagarme_api_response)
    end
    let(:create_subscription_service) do
      RecurringContribution::CreateSubscription.process(
        plan: juntos_plan,
        project: recurring_project,
        user: user,
        payment_method: payment_method,
        credit_card_hash: credit_card_hash
      )
    end

    before do
      allow_any_instance_of(RecurringContribution::Subscriptions::Pagarme).to receive(:process).and_return(pagarme_subscription_service_response)
    end

    context "when all parameters are valid" do
      context "when the payment_method is credit_card" do
        let(:payment_method) { 'credit_card' }
        let(:credit_card_hash) { build(:credit_card) }

        it "should return a persisted instance of Subscription model" do
          expect(create_subscription_service).to be_persisted
        end
      end

      context "when the payment_method is bank_billet" do
        let(:payment_method) { 'bank_billet' }
        let(:credit_card_hash) { nil }

        it "should return a persisted instance of Subscription model" do
          expect(create_subscription_service).to be_persisted
        end
      end
    end

    context "when invalid parameters are sent" do
      let(:payment_method) { 'invalid payment_method' }
      let(:credit_card_hash) { nil }

      it "should return a non persisted instance of Subscription model" do
        expect(create_subscription_service).to be_new_record
      end
    end
  end
end
