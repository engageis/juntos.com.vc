require 'rails_helper'

RSpec.describe SubscriptionPolicy do
  subject{ SubscriptionPolicy }

  shared_examples_for "create permissions" do
    let(:subscription) { create(:subscription) }
    let(:user) { nil }
    let(:policy) { subject.new(user, subscription) }

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

  permissions :cancel? do
    it_behaves_like "create permissions"
  end

  describe ".permitted_attributes" do
    let(:subscription_permitted_attributes) do
      [:plan_id, :project_id, :user_id, :payment_method, :charging_day, :charges]
    end

    subject { SubscriptionPolicy.new(user, subscription).permitted_attributes }

    context "when user is nil" do
      let(:user) { nil }
      let(:subscription) { build(:subscription) }

      it "returns an empty array" do
        expect(subject).to eq []
      end
    end

    context "when user is not nil" do
      let(:user) { create(:user) }
      let(:subscription) { build(:subscription, user: user) }

      context "and user is the subscription owner" do
        it "returns an array containing all the permitted subscription attributes" do
          expect(subject).to match_array subscription_permitted_attributes
        end
      end

      context "and user is admin" do
        it "returns an array containing all the permitted subscription attributes" do
          expect(subject).to match_array subscription_permitted_attributes
        end
      end
    end
  end
end
