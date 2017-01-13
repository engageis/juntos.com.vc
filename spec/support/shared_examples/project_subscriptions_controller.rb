RSpec.shared_examples "when a redirect is called on cancel action" do
  it "redirect back to the user panel" do
    expect(response).to redirect_to user_path(user)
  end
end
