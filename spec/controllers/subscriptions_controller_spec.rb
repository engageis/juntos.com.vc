require 'rails_helper'

RSpec.describe SubscriptionsController, type: :controller do
  describe "POST update_status" do
    let!(:subscription) { create(:subscription, subscription_code: 10, status: 'unpaid') }
    let(:pagarme_request_params) do
      {
        id:             '10',
        event:          'subscription_status_changed',
        object:         'subscription',
        old_status:     'unpaid',
        current_status: 'paid',
        desired_status: 'paid'
      }
    end

    context "when the request is sent by PagarMe" do
      before do
        allow(RecurringContribution::Subscriptions::UpdateStatus).to receive(:process)
      end

      it "returns a successful status code" do
        post :update_status, pagarme_request_params
        expect(response).to have_http_status(200)
      end

      it "must call the UpdateSubscriptionStatus service" do
        expect(RecurringContribution::Subscriptions::UpdateStatus).to receive(:process).with(controller.request)
        post :update_status, pagarme_request_params
      end
    end

    context "when the request is not sent by PagarMe" do
      before do
        allow(RecurringContribution::Subscriptions::UpdateStatus)
          .to receive(:process)
          .and_raise(RecurringContribution::Subscriptions::UpdateStatus::InvalidRequestError)
      end

      it "returns a bad request status code" do
        post :update_status, pagarme_request_params
        expect(response).to have_http_status(400)
      end
    end
  end
end
