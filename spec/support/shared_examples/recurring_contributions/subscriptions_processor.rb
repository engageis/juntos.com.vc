RSpec.shared_examples "subscription paid with credit_card" do
  context "when paid with credit_card" do
    let(:subscription)         { build(:subscription, :credit_card_payment) }
    let(:credit_card_hash)     { build(:credit_card) }
    let(:credit_card_response) { double('Card', id: 'card_ci6y37h16wrxsmzyi') }

    subject do
      RecurringContribution::Subscriptions::Processor.process(
        subscription: subscription,
        credit_card_hash: credit_card_hash
      )
    end

    before do
      allow(Pagarme::API)
        .to receive(:create_credit_card).and_return(credit_card_response)
    end

    it "should return an instance with a credit_card_key different than nil" do
      expect(subject.credit_card_key).to eq credit_card_response.id
    end
  end
end

RSpec.shared_examples "subscription paid with bank_billet" do
  context "when paid with bank_billet" do
    let(:subscription) { build(:subscription, :bank_billet_payment) }

    subject { RecurringContribution::Subscriptions::Processor.process(subscription: subscription) }

    it "should return an instance with a nil credit_card_key attribute" do
      expect(subject.credit_card_key).to be_nil
    end
  end
end

RSpec.shared_examples "when invalid attributes were sent to Subscriptions::Processor service" do
  context "when the instance contains invalid attributes" do
    let(:subscription) do
      Subscription.create(
        status:         :waiting_for_charging_day,
        payment_method: :bank_billet,
        charging_day:   5,
        plan_id:        nil,
        user_id:        nil,
        project_id:     nil
      )
    end

    subject do
      RecurringContribution::Subscriptions::Processor.process(subscription: subscription)
    end

    it "should return a subscription instance with errors" do
      expect(subject.errors.any?).to be true
    end
  end

  context "when a problem occurs on pagarme credit card creation" do
    let(:subscription)         { build(:subscription, :credit_card_payment) }
    let(:credit_card_hash)     { build(:credit_card) }

    subject do
      RecurringContribution::Subscriptions::Processor.process(
        subscription:    subscription,
        credit_card_hash: credit_card_hash
      )
    end

    it "should return a subscription instance with the errors hash having the :credit_card_key key" do
      allow(Pagarme::API)
        .to receive(:create_credit_card).and_raise(Pagarme::API::InvalidAttributeError)

      expect(subject.errors).to have_key(:credit_card_key)
    end
  end
end
