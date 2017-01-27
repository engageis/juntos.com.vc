RSpec.shared_examples "pagarme's gem create method" do
  context "when an invalid attribute is sent" do
    let(:attributes) { { invalid_attribute: 'invalid' } }

    it "should raise InvalidAttributeError" do
      VCR.use_cassette("pagarme/#{resource}/invalid_attributes_error") do
        expect { subject }.to raise_error Pagarme::API::InvalidAttributeError
      end
    end
  end

  context "when all the attributes sent are valid" do
    it "returns the new resource" do
      VCR.use_cassette("pagarme/#{resource}/create") do
        expect(subject).to respond_to :id
      end
    end
  end
end
