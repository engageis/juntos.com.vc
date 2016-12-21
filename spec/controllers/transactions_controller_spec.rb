require 'rails_helper'

RSpec.describe TransactionsController, type: :controller do
  describe "POST update_status" do
    it_behaves_like "update status controller's method" do
      let!(:resource) { create(:transaction, transaction_code: 10, status: 'processing') }
      let(:pagarme_request_params) do
        {
          id:             '10',
          event:          'transaction_status_changed',
          object:         'transaction',
          old_status:     'processing',
          current_status: 'paid',
          desired_status: 'paid'
        }
      end
    end
  end
end
