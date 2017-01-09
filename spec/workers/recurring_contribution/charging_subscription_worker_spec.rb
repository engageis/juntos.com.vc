require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe RecurringContribution::ChargingSubscriptionWorker do
  describe "#perform" do
    let(:current_date) { DateTime.current.change(day: 15) }

    context "when there is one or more juntos' subscription with the waiting_for_charging_day status" do
      context "when the subscription charging_day is equal to the current day" do
        before do
          create_list(:subscription, 5, :waiting_for_charging_day, charging_day: 13)
          create_list(:subscription, 5, :waiting_for_charging_day, charging_day: 15)
          create_list(:subscription, 2, :waiting_for_charging_day, charging_day: 18)
          create_list(:subscription, 3, :unpaid)
        end

        it "creates the pagarme's subscriptions for each juntos' subscription found" do
          Timecop.freeze(current_date) do
            expect(RecurringContribution::Subscriptions::Create)
              .to receive(:process).exactly(5).times

            Sidekiq::Testing.inline! do
              RecurringContribution::ChargingSubscriptionWorker.perform_async
            end
          end
        end
      end
    end

    context "when there is no juntos subscriptions with the waiting_for_charging_day status" do
      before do
        create_list(:subscription, 5, :waiting_for_charging_day, charging_day: 13)
        create_list(:subscription, 2, :waiting_for_charging_day, charging_day: 18)
        create_list(:subscription, 3, :unpaid)
      end

      it "does not create pagarme subscriptions" do
        Timecop.freeze(current_date) do
          expect(RecurringContribution::Subscriptions::Create)
            .to_not receive(:process)

          Sidekiq::Testing.inline! do
            RecurringContribution::ChargingSubscriptionWorker.perform_async
          end
        end
      end
    end
  end
end
