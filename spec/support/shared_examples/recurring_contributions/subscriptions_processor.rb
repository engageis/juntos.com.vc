RSpec.shared_examples "subscription paid with credit_card" do
  context "when paid with credit_card" do
    let(:subscription)         { build(:subscription, :credit_card_payment, donator_cpf: '123.456.789-11') }
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

    it "returns an instance with a credit_card_key different than nil" do
      expect(subject.credit_card_key).to eq credit_card_response.id
    end

    it "updates the user's cpf" do
      expect(subject.user.cpf).to match '123.456.789-11'
    end
  end
end

RSpec.shared_examples "subscription paid with bank_billet" do
  context "when paid with bank_billet" do
    let(:subscription) { build(:subscription, :bank_billet_payment, donator_cpf: '123.456.789-11') }

    subject { RecurringContribution::Subscriptions::Processor.process(subscription: subscription) }

    it "should return an instance with a nil credit_card_key attribute" do
      expect(subject.credit_card_key).to be_nil
    end

    it "updates the user's cpf" do
      expect(subject.user.cpf).to match '123.456.789-11'
    end
  end
end

RSpec.shared_examples "when invalid attributes were sent to Subscriptions::Processor service" do
  context "when the instance contains invalid attributes" do
    let(:subscription) { build(:subscription, :bank_billet_payment, plan_id: nil) }

    subject do
      RecurringContribution::Subscriptions::Processor.process(subscription: subscription)
    end

    it "should return a subscription instance with errors" do
      expect(subject.errors.any?).to be true
    end

    context "when the donator_cpf is nil" do
      let(:subscription) { build(:subscription, :bank_billet_payment, donator_cpf: nil) }

      it "returns an error" do
        expect(subject.errors).to have_key(:donator_cpf)
      end
    end

    context "when the donator_cpf is empty" do
      let(:subscription) { build(:subscription, :bank_billet_payment, donator_cpf: '') }

      it "returns an error" do
        expect(subject.errors).to have_key(:donator_cpf)
      end
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
