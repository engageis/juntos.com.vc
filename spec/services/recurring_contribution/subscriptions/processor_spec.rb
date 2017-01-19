require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::Processor do
  describe ".process" do
    context "when the 'with_save' parameter is true" do
      context "when the subscription instance has no invalid attributes" do
        let(:subscription) { build(:subscription, :bank_billet_payment) }
        subject { RecurringContribution::Subscriptions::Processor.process(subscription: subscription) }

        it_behaves_like "subscription paid with credit_card"

        it_behaves_like "subscription paid with bank_billet"

        it { is_expected.to be_persisted }

        context "and the charging_day choosen by the user is the same day of the process call" do
          let(:day_of_process_call) { DateTime.current.change(day: 15) }
          let(:subscription) { build(:subscription, :bank_billet_payment, charging_day: 15) }

          it "creates a juntos subscription with :pending_payment status before the pagarme's creation" do
            allow_any_instance_of(RecurringContribution::Subscriptions::Create)
              .to receive(:process)

            Timecop.freeze(day_of_process_call) do
              expect(subject.status).to eq 'pending_payment'
            end
          end

          it "creates the subscription on pagarme" do
            Timecop.freeze(day_of_process_call) do
              expect(RecurringContribution::Subscriptions::Create)
                .to receive(:process).once

              subject
            end
          end
        end
      end

      it_behaves_like "when invalid attributes were sent to Subscriptions::Processor service"
    end

    context "when the 'with_save' parameter is false" do
      context "when the subscription instance has no invalid attributes" do
        let(:subscription) { build(:subscription, :bank_billet_payment) }
        subject { RecurringContribution::Subscriptions::Processor.process(subscription: subscription, with_save: false) }

        it_behaves_like "subscription paid with credit_card"

        it_behaves_like "subscription paid with bank_billet"

        it "should return a valid subscription instance" do
          expect(subject).to be_valid
        end

        it "should return a non persisted instance" do
          expect(subject.persisted?).to eq false
        end
      end

      it_behaves_like "when invalid attributes were sent to Subscriptions::Processor service"
    end
  end
end
