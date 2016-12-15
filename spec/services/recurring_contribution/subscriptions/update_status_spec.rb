require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::UpdateStatus do
  include RecurringContributionsHelper

  describe ".process" do
    let(:pagarme_subscription) { build_subscription_mock('credit_card') }
    let!(:juntos_subscription) { create(:subscription, subscription_code: pagarme_subscription.id, status: 'pending_payment') }
    let(:update_subscription_service) { described_class.process(pagarme_subscription.id, current_status) }

    context "when the current status is permitted" do
      let(:current_status) { 'paid' }

      it "updates the Subscription status" do
        expect{ update_subscription_service }.to change { juntos_subscription.reload.status }.from('pending_payment').to('paid')
      end
    end

    context "when an invalid status is passed as param" do
      let(:current_status) { 'invalid status' }

      it "returns an invalid subscription instance" do
        expect(update_subscription_service).to be_invalid
      end
    end
  end
end
