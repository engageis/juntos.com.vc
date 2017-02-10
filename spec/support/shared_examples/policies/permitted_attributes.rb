RSpec.shared_examples_for "resource permitted attributes method" do
  context "when user is nil" do
    let(:user) { nil }
    let(:resource) { build(resource_name) }

    it "returns an empty array" do
      expect(subject).to eq []
    end
  end

  context "when user is not nil" do
    let(:user) { create(:user) }
    let(:resource) { build(resource_name, user: user) }

    context "and user is the resource owner" do
      it "returns an array containing all the permitted resource attributes" do
        expect(subject).to match_array permitted_attributes
      end
    end

    context "and user is admin" do
      it "returns an array containing all the permitted resource attributes" do
        expect(subject).to match_array permitted_attributes
      end
    end
  end
end
