require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::Processor do
  describe ".process" do
    context "when the 'with_save' parameter is true" do
      context "when the subscription instance has no invalid attributes" do
        let(:subscription) { build(:subscription, :bank_billet_payment) }
        subject { RecurringContribution::Subscriptions::Processor.process(subscription: subscription) }

        it_behaves_like "subscription paid with credit_card"

        it_behaves_like "subscription paid with bank_billet"

        it "should return a persisted subscription instance" do
          expect(subject.persisted?).to eq true
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
