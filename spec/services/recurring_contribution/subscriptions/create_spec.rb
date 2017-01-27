require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::Create do
  describe '.process' do
    let(:pagarme_plan) { build_plan_mock(id: 100) }
    let!(:juntos_plan) { create(:plan, plan_code: pagarme_plan.id) }
    let(:recurring_project) { create(:project) }
    let(:user) { create(:user) }

    context "when all parameters are valid" do
      before do
        allow_any_instance_of(RecurringContribution::Subscriptions::CreatePagarme)
          .to receive(:process).and_return(pagarme_api_response)
      end

      context "when the payment_method is credit_card" do
        let(:payment_method) { 'credit_card' }
        let(:pagarme_api_response) { build_subscription_mock(payment_method, pagarme_plan) }
        let(:juntos_subscription) do
          create(:subscription, plan: juntos_plan, project: recurring_project, user: user,
                 payment_method: payment_method, credit_card_key: 'card_ci6y37h16wrxsmzyi')
        end
        subject { RecurringContribution::Subscriptions::Create.process(juntos_subscription) }


        it "should return an updated juntos' subscription" do
          expect(subject.subscription_code).to eq pagarme_api_response.id
        end
      end

      context "when the payment_method is bank_billet" do
        let(:payment_method) { 'bank_billet' }
        let(:pagarme_api_response) { build_subscription_mock(payment_method, pagarme_plan) }
        let(:juntos_subscription) do
          create(:subscription, plan: juntos_plan, project: recurring_project, user: user,
                 payment_method: payment_method)
        end
        subject { RecurringContribution::Subscriptions::Create.process(juntos_subscription) }

        it "should return an updated juntos' subscription" do
          expect(subject.subscription_code).to eq pagarme_api_response.id
        end
      end
    end

    context "when a problem occurs with the pagarme's subscription creation" do
      let(:pagarme_api_response) { nil }
      let(:juntos_subscription) { create(:subscription, plan: juntos_plan, project: recurring_project, user: user) }
      subject { RecurringContribution::Subscriptions::Create.process(juntos_subscription) }

      context "when an invalid subscription attribute is sent" do
        it "should raise a Pagarme::API::InvalidAttributeError" do
          allow_any_instance_of(RecurringContribution::Subscriptions::CreatePagarme)
            .to receive(:process).and_raise(Pagarme::API::InvalidAttributeError)

          expect { subject }
            .to raise_error(Pagarme::API::InvalidAttributeError)
        end
      end

      context "when the connection is lost" do
        it "should raise a Pagarme::API::ConnectionError" do
          allow_any_instance_of(RecurringContribution::Subscriptions::CreatePagarme)
            .to receive(:process).and_raise(Pagarme::API::ConnectionError)

          expect { subject }
            .to raise_error(Pagarme::API::ConnectionError)
        end
      end
    end
  end
end
