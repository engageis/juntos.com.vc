RSpec.shared_examples "update status service" do
  describe ".process" do
    before do
      allow(Pagarme::API).to receive(:valid_request_signature?).and_return pagarme_request?
    end

    context "when the request is made from PagarMe" do
      let(:pagarme_request?) { true }
      context "when the current status is permitted" do
        let(:current_status) { 'paid' }
        let(:params) { { id: pagarme_resource.id, current_status: current_status } }
        let(:request) { double('Request', params: params) }
        let(:update_service) { described_class.process(request, juntos_resource) }

        it "updates the resource status" do
          expect{ update_service }
            .to change { juntos_resource.reload.status }
            .from('pending_payment').to('paid')
        end
      end

      context "when an invalid status is passed as param" do
        let(:current_status) { 'invalid status' }
        let(:params) { { id: pagarme_resource.id, current_status: current_status } }
        let(:request) { double('Request', params: params) }
        let(:update_service) { described_class.process(request, juntos_resource) }

        it "returns an invalid resource instance" do
          expect(update_service).to be_invalid
        end
      end
    end

    context "when the request is made by an unauthorized resource" do
      let(:pagarme_request?) { false }
      let(:current_status) { 'paid' }
      let(:params) { { id: pagarme_resource.id, current_status: current_status } }
      let(:request) { double('Request', params: params) }
      let(:update_service) { described_class.process(request, juntos_resource) }

      it "must raise an InvalidRequestError" do
        expect{ update_service }
        .to raise_error(RecurringContribution::UpdateStatus::InvalidRequestError)
      end
    end
  end
end
