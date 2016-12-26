require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::CreatePagarme do
  describe "#process" do
    let(:plan) { create(:plan, plan_code: 73197) }
    let(:user) { create(:user) }
    let(:project) { create(:project, user: user) }
    let(:pagarme_credit_card) do
      Pagarme::API.create_credit_card({
        card_number: '5106961093083678',
        card_holder_name: 'Juntos',
        card_expiration_month: '07',
        card_expiration_year: '17',
        card_cvv: '906'
      })
    end

    context "when the parameters sent are valid" do
      let(:juntos_subscription) do
        VCR.use_cassette('recurring_contributions/pagarme/credit_card') do
          create(:subscription, plan: plan, user: user, project: project,
                 payment_method: 'credit_card', credit_card_key: pagarme_credit_card.id)
        end
      end
      subject do
        RecurringContribution::Subscriptions::CreatePagarme.new(juntos_subscription).process
      end

      it "should create a pagarme's subscription" do
        VCR.use_cassette('recurring_contributions/pagarme/credit_card_subscription_build') do
          expect(subject.id).to_not be_nil
        end
      end

      context "payment_method attribute" do
        context "when credit_card" do
          let(:juntos_subscription) do
            VCR.use_cassette('recurring_contributions/pagarme/credit_card') do
              create(:subscription, plan: plan, user: user, project: project,
                     payment_method: 'credit_card', credit_card_key: pagarme_credit_card.id)
            end
          end
          subject do
            RecurringContribution::Subscriptions::CreatePagarme.new(juntos_subscription).process
          end

          it "should return a pagarme's subscription with a valid credit_card" do
            VCR.use_cassette('recurring_contributions/pagarme/credit_card_subscription_build') do
              expect(subject.card.valid).to eq true
            end
          end
        end

        context "when bank_billet" do
          let(:juntos_subscription) do
            create(:subscription, plan: plan, user: user, project: project,
                   payment_method: 'bank_billet')
          end
          subject do
            RecurringContribution::Subscriptions::CreatePagarme.new(juntos_subscription).process
          end

          it "should return a pagarme's subscription with the bank_billet information" do
            VCR.use_cassette('recurring_contributions/pagarme/bank_billet_subscription_build') do
              expect(subject.payment_method).to match 'boleto'
            end
          end

          it "should return a pagarme's subscription with the unpaid status" do
            VCR.use_cassette('recurring_contributions/pagarme/bank_billet_subscription_build') do
              expect(subject.status).to match 'unpaid'
            end
          end
        end
      end
    end
  end
end
