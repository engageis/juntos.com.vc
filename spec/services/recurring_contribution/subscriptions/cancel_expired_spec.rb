require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::CancelExpired do
  describe ".process" do
    let(:subscriptions) do
      {
        subscription.subscription_code => subscription,
        subscription_2.subscription_code => subscription_2
      }
    end

    let(:ten_charges)  { 10 }
    let(:five_charges) { 5 }
    let(:credit_card_ten_charges)  { ten_charges + 1 }
    let(:credit_card_five_charges) { five_charges + 1 }
    let(:parsed_response) do
      [
        {
          charges: ten_charges,
          id: subscription.subscription_code
        },
        {
          charges: five_charges,
          id: subscription_2.subscription_code
        }
      ]
    end

    subject { described_class.process(subscriptions) }

    before do
      allow(Pagarme::Request::Subscription).to receive(:retrieve_pagarme_subscriptions).and_return(parsed_response)
      allow(Pagarme::Request::Subscription).to receive(:cancel_subscriptions)

      subject
    end

    context "when the subscription payment method is credit card" do
      context "and the credit card charges matches the parsed_response" do
        let(:subscription) do
          create(:subscription, :credit_card_payment, :paid, :expired, charges: credit_card_ten_charges)
        end
        let(:subscription_2) do
          create(:subscription, :credit_card_payment, :paid, :expired, charges: credit_card_five_charges)
        end

        it "should call 'cancel_subscriptions' method" do
          expect(Pagarme::Request::Subscription).to have_received(:cancel_subscriptions).once
        end
      end

      context "and the credit card charges does not match the parsed_response" do
        let(:subscription) do
          create(:subscription, :credit_card_payment, :paid, :expired, charges: 12)
        end
        let(:subscription_2) do
          create(:subscription, :credit_card_payment, :paid, :expired, charges: 7)
        end

        it "should not call 'cancel_subscriptions' method" do
          expect(Pagarme::Request::Subscription).to have_received(:cancel_subscriptions).with([])
        end
      end
    end

    context "when the subscription payment method is bank billet" do
      context "and the charges matches the parsed_response" do
        let(:subscription) do
          create(:subscription, :bank_billet_payment, :paid, :expired, charges: ten_charges)
        end
        let(:subscription_2) do
          create(:subscription, :bank_billet_payment, :paid, :expired, charges: five_charges)
        end

        it "should call 'cancel_subscriptions' method" do
          expect(Pagarme::Request::Subscription).to have_received(:cancel_subscriptions).once
        end
      end

      context "and the credit card charges does not match the parsed_response" do
        let(:subscription) do
          create(:subscription, :bank_billet_payment, :paid, :expired, charges: 11)
        end
        let(:subscription_2) do
          create(:subscription, :bank_billet_payment, :paid, :expired, charges: 6)
        end

        it "should not call 'cancel_subscriptions' method" do
          expect(Pagarme::Request::Subscription).to have_received(:cancel_subscriptions).with([])
        end
      end
    end
  end
end
