require 'rails_helper'

RSpec.describe RecurringContribution::UpdateStatus do
  include RecurringContributionsHelper

  context "when the resource is a Subscription" do
    it_behaves_like "update status service" do
      let(:pagarme_resource) { build_subscription_mock('credit_card') }
      let!(:juntos_resource) { create(:subscription, subscription_code: pagarme_resource.id, status: 'pending_payment') }
    end
  end

  context "when the resource is a Transaction" do
    it_behaves_like "update status service" do
      let(:pagarme_resource) { build_transaction_mock }
      let!(:juntos_resource) { create(:transaction, transaction_code: pagarme_resource.id, status: 'pending_payment') }
    end
  end
end
