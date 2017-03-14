require 'rails_helper'

RSpec.describe RecurringContribution::Subscriptions::UpdateJuntos do
  describe "#process" do
    let(:pagarme_plan) { build_plan_mock(id: 10) }
    let!(:juntos_plan) { create(:plan, plan_code: pagarme_plan.id) }
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:juntos_subscription) { create(:subscription, plan: juntos_plan, project: project, user: user, payment_method: 'credit_card') }

    context "when all the parameters sent are valid" do
      let(:pagarme_subscription) { build_subscription_mock('credit_card', pagarme_plan) }
      let(:juntos_subscription_service) do
        RecurringContribution::Subscriptions::UpdateJuntos.new(juntos_subscription, pagarme_subscription)
      end
      let(:service_response) { juntos_subscription_service.process }
      let(:juntos_created_transaction) { service_response.transactions.first }

      around do |test_case|
        Timecop.freeze do
          test_case.run
        end
      end

      it "should update the subscription with a subscription_code equal to pagarme's subscription id" do
        expect(service_response.subscription_code).to eq(pagarme_subscription.id)
      end

      it "should create the first transaction for the received juntos' subscription" do
        expect(juntos_created_transaction).to have_attributes(status: 'waiting_payment', payment_method: 'credit_card')
      end

      it "should create a transaction model with transaction_code equal to pagarme's transaction id" do
        expect(juntos_created_transaction.transaction_code).to eq(pagarme_subscription.current_transaction.id)
      end

      it "sets the confirmed_at to the current date" do
        expect(service_response.confirmed_at).to eq(Time.current)
      end
    end

    context "when an invalid pagarme subscription is sent as parameter" do
      let(:pagarme_subscription) { build_subscription_mock('credit_card', pagarme_plan) }
      let(:juntos_subscription_service) do
        RecurringContribution::Subscriptions::UpdateJuntos.new(juntos_subscription, pagarme_subscription)
      end
      let(:service_response) { juntos_subscription_service.process }

      context "when the pagarme's subscription id is nil" do
        it "should raise an InvalidPagarmeSubscription error" do
          allow(pagarme_subscription).to receive(:id).and_return(nil)

          expect { service_response }
            .to raise_error(RecurringContribution::Subscriptions::UpdateJuntos::InvalidPagarmeSubscription)
        end
      end
    end
  end
end
