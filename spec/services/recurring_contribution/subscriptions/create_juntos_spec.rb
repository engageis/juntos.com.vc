require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::CreateJuntos do
  describe ".process" do
    let(:project)     { create(:project) }
    let(:plan)        { create(:plan) }

    context "when all parameters sent are valid" do
      subject do
        RecurringContribution::Subscriptions::CreateJuntos.process(
          project:          project,
          plan:             plan,
          user:             project.user,
          payment_method:   'bank_billet',
          charging_day:     5
        )
      end

      context "payment_method" do
        subject do
          RecurringContribution::Subscriptions::CreateJuntos.process(
            project:          project,
            plan:             plan,
            user:             project.user,
            payment_method:   payment_method,
            charging_day:     5,
            credit_card_hash: credit_card_attributes
          )
        end

        context "when credit card" do
          let(:payment_method) { 'credit_card' }
          let(:credit_card_attributes) { build(:credit_card) }
          let(:pagarme_response_for_card_creation) { double('Card', id: 'card_ci6y37h16wrxsmzyi') }

          it "should create a PagarMe::Card" do
            allow(Pagarme::API).to receive(:create_credit_card)
              .with(credit_card_attributes).and_return(pagarme_response_for_card_creation)

            expect(subject.credit_card_key).to eq 'card_ci6y37h16wrxsmzyi'
          end
        end

        context "when bank billet" do
          let(:payment_method) { 'bank_billet' }
          let(:credit_card_attributes) { Hash.new }

          it "should create a subscription with a nil credit_card_key" do
            expect(subject.credit_card_key).to be_nil
          end
        end
      end

      it "should return a subscription with a 'waiting_for_charging_day' status" do
        expect(subject.status).to match 'waiting_for_charging_day'
      end

      it "should create a subscription" do
        expect(subject.persisted?).to eq true
      end
    end

    context "when invalid parameters are sent" do
      subject do
        RecurringContribution::Subscriptions::CreateJuntos.process(
          project:          project,
          plan:             plan,
          user:             project.user,
          payment_method:   'bank_billet',
          charging_day:     29
        )
      end

      it "returns an invalid subscription instance" do
        expect(subject).to be_invalid
      end
    end

    context "when a problem occurs with PagarMe's API on credit_card creation" do
      let(:credit_card_attributes) { build(:credit_card) }
      subject do
        RecurringContribution::Subscriptions::CreateJuntos.process(
          project:          project,
          plan:             plan,
          user:             project.user,
          payment_method:   'credit_card',
          charging_day:     5,
          credit_card_hash: credit_card_attributes
        )
      end

      context "when connection is lost" do
        it "raises a Pagarme::API::ConnectionError error" do
          allow(Pagarme::API).to receive(:create_credit_card)
            .with(credit_card_attributes).and_raise(Pagarme::API::ConnectionError)

          expect { subject }
            .to raise_error Pagarme::API::ConnectionError
        end
      end

      context "when invalid credit card parameters are sent" do
        it "raises a Pagarme::API::InvalidAttributeError error" do
          allow(Pagarme::API).to receive(:create_credit_card)
            .with(credit_card_attributes).and_raise(Pagarme::API::InvalidAttributeError)

          expect { subject }
            .to raise_error Pagarme::API::InvalidAttributeError
        end
      end
    end
  end
end
