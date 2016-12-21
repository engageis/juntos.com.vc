RSpec.shared_examples "update status controller's method" do
  context "when the request is sent by PagarMe" do
    before do
      allow(RecurringContribution::UpdateStatus).to receive(:process)
    end

    it "returns a successful status code" do
      post :update_status, pagarme_request_params
      expect(response).to have_http_status(200)
    end

    it "should call the UpdateSubscriptionStatus service" do
      expect(RecurringContribution::UpdateStatus).to receive(:process).with(controller.request, resource)
      post :update_status, pagarme_request_params
    end
  end

  context "when the request is not sent by PagarMe" do
    before do
      allow(RecurringContribution::UpdateStatus)
        .to receive(:process)
        .and_raise(RecurringContribution::UpdateStatus::InvalidRequestError)
    end

    it "returns a bad request status code" do
      post :update_status, pagarme_request_params
      expect(response).to have_http_status(400)
    end
  end
end
