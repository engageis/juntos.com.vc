require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::Pagarme do
  include RecurringContributionsHelper

  describe '#process' do
    let(:plan) { create(:plan, plan_code: 73197) }
    let(:user) { create(:user) }
    let(:credit_card) { build(:credit_card) }
    let(:bank_billet_service) {
      RecurringContribution::Subscriptions::Pagarme.new(plan.plan_code, user, 'bank_billet', credit_card).process
    }
    let(:credit_card_service) {
      RecurringContribution::Subscriptions::Pagarme.new(plan.plan_code, user, 'credit_card', credit_card).process
    }

    context 'when the subscription is successfully created' do
      let(:pagarme_subscription) { credit_card_service.pagarme_subscription }

      it "should create a subscription in the pagarme's API" do
        VCR.use_cassette('recurring_contributions/pagarme/credit_card_subscription_build') do
          expect(pagarme_subscription.id).to_not be_nil
        end
      end

      context 'payment_method attribute' do
        context 'when credit_card' do
          it 'should return a valid credit_card' do
            VCR.use_cassette('recurring_contributions/pagarme/credit_card_subscription_build') do
              expect(pagarme_subscription.card.valid).to eq(true)
            end
          end
        end

        context 'when bank_billet' do
          let(:pagarme_subscription) { bank_billet_service.pagarme_subscription }

          it 'should return the bank_billet information' do
            VCR.use_cassette('recurring_contributions/pagarme/bank_billet_subscription_build') do
              expect(pagarme_subscription.payment_method).to match('boleto')
            end
          end
        end
      end
    end
  end
end
