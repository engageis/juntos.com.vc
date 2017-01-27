RSpec.shared_examples "pagarme's gem find method" do
  subject { Pagarme::API.send(method, parameter) }

  context "when a valid id is sent as parameter" do
    let(:parameter) { 10 }

    before do
      allow(pagarme_resource_class(resource))
        .to receive(:find_by_id).and_return(pagarme_mock(resource))
    end

    it "returns the resource" do
      expect(subject).to respond_to :id
    end
  end

  context "when an invalid id is sent as parameter" do
    context "when nil" do
      let(:parameter) { nil }

      it "raises a ResourceNotFound error" do
        expect { subject }.to raise_error Pagarme::API::ResourceNotFound
      end
    end

    context "when there is no resource matching the id" do
      let(:parameter) { 0 }

      it "raises a ResourceNotFound error" do
        VCR.use_cassette("pagarme/#{resource}/invalid_id_error") do
          expect { subject }.to raise_error Pagarme::API::ResourceNotFound
        end
      end
    end
  end
end
