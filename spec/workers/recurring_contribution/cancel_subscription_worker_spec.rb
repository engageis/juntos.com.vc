require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe RecurringContribution::CancelSubscriptionWorker do
  describe "#perform" do
    context "when there are expired subscriptions" do
      let(:subscription) { create(:subscription, :paid, :expired) }
      let(:subscription_param) { { subscription.subscription_code => subscription } }

      before do
        create(:subscription, :unpaid)
        create(:subscription, :canceled)
      end

      it "should call the cancel subscription service" do
        expect(RecurringContribution::Subscriptions::CancelExpired)
          .to receive(:process).with(subscription_param).once

        Sidekiq::Testing.inline! do
          described_class.perform_async
        end
      end
    end

    context "when there are no expired subscriptions" do
      before do
        create(:subscription, :paid, :not_expired)
        create(:subscription, :unpaid)
        create(:subscription, :canceled)
        create(:subscription, :pending_payment)
        create(:subscription, :waiting_for_charging_day)
      end

      it "should not call the cancel subscription service" do
        expect(RecurringContribution::Subscriptions::CancelExpired)
          .not_to receive(:process)

        Sidekiq::Testing.inline! do
          described_class.perform_async
        end
      end
    end
  end
end
