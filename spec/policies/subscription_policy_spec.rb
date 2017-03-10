require 'rails_helper'

RSpec.describe SubscriptionPolicy do
  subject{ SubscriptionPolicy }
  let(:subscription) { create(:subscription) }

  permissions :new? do
    it_behaves_like "create permissions" do
      let(:resource) { subscription }
    end
  end

  permissions :create? do
    it_behaves_like "create permissions" do
      let(:resource) { subscription }
    end
  end

  permissions :cancel? do
    it_behaves_like "create permissions" do
      let(:resource) { subscription }
    end
  end

  describe ".permitted_attributes" do
    subject { SubscriptionPolicy.new(user, resource).permitted_attributes }

    it_behaves_like "resource permitted attributes method" do
      let(:resource_name) { :subscription }

      let(:permitted_attributes) do
        [:plan_id, :project_id, :user_id, :payment_method, :charging_day, :charges, :donator_cpf]
      end
    end
  end
end
