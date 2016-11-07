require 'rails_helper'
require 'json'

RSpec.describe RecurringContribution::UpdatePlans do
  def mocked_plans
    (1..3).map do |plan_id|
      build_plan_mock(plan_id)
    end
  end

  def build_plan_mock(plan_id)
    double("Plan", id: plan_id,
                   name: 'Foo Plan',
                   amount: 30,
                   payment_methods: ['boleto', 'credit_card'])
  end

  describe '#call' do
    let(:remote_plans) { mocked_plans }
    let(:update_plans_service) { RecurringContribution::UpdatePlans.call }
    let(:local_plans) { Plan.all }

    before(:each) do
      allow_any_instance_of(described_class).to receive(:pagarme_plans) { mocked_plans }
    end

    context "when there are remote plans that not exist in junto's database" do
      it 'must create the plans' do
        update_plans_service
        expect(remote_plans.map(&:id)).to match_array(local_plans.map(&:plan_code))
      end
    end

    context 'when all plans are updated' do
      before do
        allow_any_instance_of(described_class).to receive(:plan_exist?) { true }
      end

      it 'should return an empty array' do
        returned_value = update_plans_service
        expect(returned_value).to be_empty
      end
    end

    context 'when ActiveRecord raises an error on Plan creation' do
      before do
        allow_any_instance_of(described_class).to receive(:build_plan) { raise ActiveRecord::Rollback }
      end

      it "does not create the plans returned from PagarMe's API" do
        expect { update_plans_service }.to_not change { Plan.count }
      end
    end
  end
end
