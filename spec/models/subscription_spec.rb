require 'rails_helper'

RSpec.describe Subscription, type: :model do

  describe 'associations' do
    it{ is_expected.to belong_to :user }
    it{ is_expected.to belong_to :project }
    it{ is_expected.to belong_to :plan }
  end

  describe 'validations' do
    let(:plan) { create(:plan, :with_credit_card) }
    let(:unpermitted_payment_subscription) { build(:subscription, :bank_billet_payment, plan: plan) }
    let(:permitted_payment_subscription) { build(:subscription, :credit_card_payment, plan: plan) }

    it { is_expected.to validate_presence_of(:subscription_code) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:payment_method) }
    it { is_expected.to validate_presence_of(:plan_id) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:project_id) }

    it { is_expected.to enumerize(:payment_method).in(:credit_card, :bank_billet) }
    it { is_expected.to enumerize(:status).in(:paid, :pending_payment, :unpaid, :canceled) }

    context "when the subscription is made with a plan's unpermitted payment type" do
      it 'should be invalid' do
        expect(unpermitted_payment_subscription).to be_invalid
      end
    end

    context 'when the payment_method is permitted by the plan' do
      it 'should be valid' do
        expect(permitted_payment_subscription).to be_valid
      end
    end
  end
end
