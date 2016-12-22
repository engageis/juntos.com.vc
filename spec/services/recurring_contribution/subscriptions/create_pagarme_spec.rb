require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::CreatePagarme do
  describe "#process" do
    let(:plan) { create(:plan, plan_code: 73197) }
    let(:user) { create(:user) }
    let(:project) { create(:project, user: user) }

    context "when the parameters sent are valid" do
      let(:credit_card) { build(:credit_card) }
      let(:juntos_subscription) do
        create(:subscription, plan: plan, user: user, project: project, payment_method: 'credit_card')
      end
      let(:service_response) do
        RecurringContribution::Subscriptions::CreatePagarme.new(juntos_subscription, credit_card).process
      end

      it "should create a pagarme's subscription" do
        VCR.use_cassette('recurring_contributions/pagarme/credit_card_subscription_build') do
          expect(service_response.id).to_not be_nil
        end
      end

      context "payment_method attribute" do
        context "when credit_card" do
          let(:credit_card) { build(:credit_card) }
          let(:juntos_subscription) do
            create(:subscription, plan: plan, user: user, project: project, payment_method: 'credit_card')
          end
          let(:service_response) do
            RecurringContribution::Subscriptions::CreatePagarme.new(juntos_subscription, credit_card).process
          end

          it "should return a pagarme's subscription with a valid credit_card" do
            VCR.use_cassette('recurring_contributions/pagarme/credit_card_subscription_build') do
              expect(service_response.card.valid).to eq true
            end
          end
        end

        context "when bank_billet" do
          let(:juntos_subscription) do
            create(:subscription, plan: plan, user: user, project: project, payment_method: 'bank_billet')
          end
          let(:service_response) do
            RecurringContribution::Subscriptions::CreatePagarme.new(juntos_subscription).process
          end

          it "should return a pagarme's subscription with the bank_billet information" do
            VCR.use_cassette('recurring_contributions/pagarme/bank_billet_subscription_build') do
              expect(service_response.payment_method).to match 'boleto'
            end
          end

          it "should return a pagarme's subscription with the unpaid status" do
            VCR.use_cassette('recurring_contributions/pagarme/bank_billet_subscription_build') do
              expect(service_response.status).to match 'unpaid'
            end
          end
        end
      end
    end
  end
end
