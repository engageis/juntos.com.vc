require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::UpdateStatus do
  include RecurringContributionsHelper

  describe ".process" do
    let(:pagarme_subscription) { build_subscription_mock('credit_card') }
    let!(:juntos_subscription) { create(:subscription, subscription_code: pagarme_subscription.id, status: 'pending_payment') }

    before do
      allow(Pagarme::API).to receive(:valid_request_signature?).and_return pagarme_request?
    end

    context "when the request is made from PagarMe" do
      let(:pagarme_request?) { true }
      context "when the current status is permitted" do
        let(:current_status) { 'paid' }
        let(:params) { { id: pagarme_subscription.id, current_status: current_status } }
        let(:request) { double('Request', params: params) }
        let(:update_subscription_service) { described_class.process(request) }

        it "updates the Subscription status" do
          expect{ update_subscription_service }
            .to change { juntos_subscription.reload.status }
            .from('pending_payment').to('paid')
        end
      end

      context "when an invalid status is passed as param" do
        let(:current_status) { 'invalid status' }
        let(:params) { { id: pagarme_subscription.id, current_status: current_status } }
        let(:request) { double('Request', params: params) }
        let(:update_subscription_service) { described_class.process(request) }

        it "returns an invalid subscription instance" do
          expect(update_subscription_service).to be_invalid
        end
      end
    end

    context "when the request is made by an unauthorized resource" do
      let(:pagarme_request?) { false }
      let(:current_status) { 'paid' }
      let(:params) { { id: pagarme_subscription.id, current_status: current_status } }
      let(:request) { double('Request', params: params) }
      let(:update_subscription_service) { described_class.process(request) }

      it "must raise an InvalidRequestError" do
        expect{ update_subscription_service }
        .to raise_error(RecurringContribution::Subscriptions::UpdateStatus::InvalidRequestError)
      end
    end
  end
end
