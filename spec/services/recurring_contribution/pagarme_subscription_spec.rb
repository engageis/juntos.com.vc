require 'rails_helper'

RSpec.describe RecurringContribution::PagarmeSubscription do
  include RecurringContributionsHelper

  describe '#build' do
    let(:plan) { create(:plan, plan_code: 73197) }
    let(:user) { create(:user) }
    let(:credit_card) { build(:credit_card) }
    let(:pagarme_bank_billet_subscription) {
      RecurringContribution::PagarmeSubscription.new(plan.plan_code, user, 'bank_billet', credit_card).build
    }
    let(:pagarme_credit_card_subscription) {
      RecurringContribution::PagarmeSubscription.new(plan.plan_code, user, 'credit_card', credit_card).build
    }

    context 'when the subscription is successfully created' do
      it "should create a subscription in the pagarme's API" do
        VCR.use_cassette('recurring_contributions/pagarme/credit_card_subscription_build') do
          expect(pagarme_credit_card_subscription.id).to_not be_nil
        end
      end

      context 'payment_method attribute' do
        context 'when credit_card' do
          it 'should return a valid credit_card' do
            VCR.use_cassette('recurring_contributions/pagarme/credit_card_subscription_build') do
              expect(pagarme_credit_card_subscription.card.valid).to eq true
            end
          end
        end

        context 'when bank_billet' do
          it 'should return the bank_billet information' do
            VCR.use_cassette('recurring_contributions/pagarme/bank_billet_subscription_build') do
              expect(pagarme_bank_billet_subscription.payment_method).to match('boleto')
            end
          end
        end
      end
    end
  end
end
