require 'rails_helper'

RSpec.describe SubscriptionsController, type: :controller do
  describe "POST update_status" do
    it_behaves_like "update status controller's method" do
      let!(:resource) { create(:subscription, subscription_code: 10, status: 'unpaid') }
      let(:pagarme_request_params) do
        {
          id:             '10',
          event:          'subscription_status_changed',
          object:         'subscription',
          old_status:     'unpaid',
          current_status: 'paid',
          desired_status: 'paid'
        }
      end
    end
  end
end
