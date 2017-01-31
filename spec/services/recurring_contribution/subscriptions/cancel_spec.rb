require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::Cancel do
  describe ".process" do

    context "when the subscription exists on pagarme" do
      let(:subscription) { create(:subscription, :paid) }
      let(:pagarme_subscription_response) do
        {
          object: 'Subscription',
          status: 'canceled'
        }
      end

      before do
        allow(Pagarme::API).to receive(:find_subscription).and_return(subscription)
        allow(Pagarme::API).to receive(:cancel_subscription).and_return(pagarme_subscription_response)
      end

      subject { RecurringContribution::Subscriptions::Cancel.process(subscription) }

      it "should update the pagarme's subscription status to 'canceled'" do
        expect(subject[:status]).to eq 'canceled'
      end
    end

    context "when the subscription exists on local database only" do
      let(:subscription) { create(:subscription, :paid, subscription_code: nil) }

      before { RecurringContribution::Subscriptions::Cancel.process(subscription) }

      it { expect(subscription.reload).to be_canceled }
    end

    context "when a problem occurs with the PagarMe's API" do
      let(:subscription) { build(:subscription) }

      subject { RecurringContribution::Subscriptions::Cancel.process(subscription) }

      context "when the pagarme subscription does not exist" do
        it "should raise a Pagarme::API::ResourceNotFound" do
          allow(Pagarme::API).to receive(:find_subscription).and_raise(Pagarme::API::ResourceNotFound)
          expect { subject }.to raise_error(Pagarme::API::ResourceNotFound)
        end
      end

      context "when the PagarMe API is offline" do
        it "should raise a Pagarme::API::ConnectionError" do
          allow(Pagarme::API).to receive(:find_subscription).and_raise(Pagarme::API::ConnectionError)
          expect { subject }.to raise_error(Pagarme::API::ConnectionError)
        end
      end
    end
  end
end
