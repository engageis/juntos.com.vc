require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::CancelOnPagarme do
  describe ".process" do
    context "when an existent subscription was passed as parameter" do
      let(:pagarme_subscription) { build(:subscription, status: 'paid') }
      let(:pagarme_subscription_response) do
        {
          object: 'Subscription',
          status: 'canceled'
        }
      end
      subject { RecurringContribution::Subscriptions::CancelOnPagarme.process(pagarme_subscription) }

      it "should update the pagarme's subscription status to 'canceled'" do
        allow(Pagarme::API).to receive(:find_subscription).and_return(pagarme_subscription)
        allow(Pagarme::API).to receive(:cancel_subscription).and_return(pagarme_subscription_response)

        expect(subject[:status]).to eq 'canceled'
      end
    end

    context "when a problem occurs with the PagarMe's API" do
      let(:pagarme_subscription) { build(:subscription) }
      subject { RecurringContribution::Subscriptions::CancelOnPagarme.process(pagarme_subscription) }

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
