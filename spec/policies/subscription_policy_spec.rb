require 'rails_helper'

RSpec.describe SubscriptionPolicy do
  subject{ SubscriptionPolicy }

  let(:subscription) { create(:subscription) }
  let(:user) { nil }
  let(:policy) { subject.new(user, subscription) }

  shared_examples_for "create permissions" do
    it "should deny the access if no user is logged" do
      is_expected.not_to permit(nil, subscription)
    end

    it "should deny the access if the logged user is not the subscriber" do
      is_expected.not_to permit(User.new, subscription)
    end

    it "should permit the access if the user is admin" do
      is_expected.not_to permit(nil, subscription)
    end
  end

  permissions :new? do
    it_behaves_like "create permissions"
  end

  permissions :create? do
    it_behaves_like "create permissions"
  end
end
