require 'rails_helper'

RSpec.describe Pagarme::API do
  [:plan, :subscription, :transaction].each do |resource|
    describe ".find_#{resource}" do
      it_behaves_like "pagarme's gem find method" do
        let(:resource) { resource }
        let(:method)   { "find_#{resource}" }
      end
    end
  end

  describe ".create_subscription" do
    subject { Pagarme::API.create_subscription(attributes) }

    it_behaves_like "pagarme's gem create method" do
      let(:resource) { :subscription }

      let(:pagarme_plan) do
        VCR.use_cassette("pagarme/plan/find") do
          Pagarme::API.find_plan(73197)
        end
      end

      let(:attributes) do
        {
          payment_method: 'boleto',
          customer: {
            email: 'foo@user.com'
          },
          plan: pagarme_plan
        }
      end
    end
  end

  describe ".create_credit_card" do
    subject { Pagarme::API.create_credit_card(attributes) }

    it_behaves_like "pagarme's gem create method" do
      let(:resource)   { :credit_card }
      let(:attributes) { build(:credit_card) }
    end
  end

  describe ".cancel_subscription" do
    subject { Pagarme::API.cancel_subscription(subscription) }

    context "when nil is passed as parameter" do
      let(:subscription) { nil }

      it "raises a ResourceNotFound error" do
        expect{ subject }.to raise_error Pagarme::API::ResourceNotFound
      end

    end

    context "when a subscription is passed as parameter" do
      let(:subscription) { PagarMe::Subscription.new }
      let(:pagarme_response) do
        {
          object: 'subscription',
          status: 'canceled'
        }
      end

      before do
        allow_any_instance_of(PagarMe::Subscription)
          .to receive(:cancel).and_return(pagarme_response)
      end

      it "returns the canceled subscription on json format" do
        expect(subject).to eq pagarme_response
      end
    end
  end
end
