RSpec.shared_examples_for "create permissions" do
  let(:admin) { create(:user, admin: true) }

  it "should deny the access if no user is logged" do
    is_expected.not_to permit(nil, resource)
  end

  it "should deny the access if the logged user is not the subscriber" do
    is_expected.not_to permit(User.new, resource)
  end

  it "should permit the access if the user is admin" do
    is_expected.to permit(admin, resource)
  end
end
