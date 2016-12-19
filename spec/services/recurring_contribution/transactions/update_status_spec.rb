require 'rails_helper'

RSpec.describe RecurringContribution::Transactions::UpdateStatus do
  include RecurringContributionsHelper

  it_behaves_like "update status service" do
    let(:pagarme_resource) { build_transaction_mock }
    let!(:juntos_resource) { create(:transaction, transaction_code: pagarme_resource.id, status: 'pending_payment') }
  end
end
