require 'rails_helper'
require 'json'

RSpec.describe RecurringContribution::UpdatePlans do
  describe '#call' do
    before(:each) do
      allow(Pagarme::API).to receive(:fetch_plans) { pagarme_plans }

      RecurringContribution::UpdatePlans.call
    end

    context "when there are remote plans" do
      let(:persisted_plan) { Plan.find_by(plan_code: plan_code) }

      context "and the plan exists on Juntos' database" do
        let(:plan_code)     { 10 }
        let(:plan)          { create(:plan, plan_code: 10, name: 'first_created') }
        let(:pagarme_plans) { [build_plan_mock(id: plan.plan_code, name: 'override_name')] }

        it { expect(persisted_plan.name).to eq('first_created') }
      end

      context "and the plan does not exist on Juntos' database" do
        let(:plan_code)     { 5 }
        let(:pagarme_plans) { [build_plan_mock(id: plan_code, trial_days: trial_days)] }

        context "and it is not a trial plan" do
          let(:trial_days) { 0 }

          it { expect(persisted_plan.plan_code).to eq(plan_code) }
        end

        context "and it is a trial plan" do
          let(:trial_days) { 1 }

          it { expect(persisted_plan).to be_nil }
        end
      end
    end

    context "when there are no remote plans" do
      let(:pagarme_plans) { [] }

      it { expect(Plan.count).to be_zero }
    end
  end
end
