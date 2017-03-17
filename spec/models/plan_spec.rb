require 'rails_helper'

RSpec.describe Plan, :type => :model do
  let(:invalid_payment_method_plan) { build(:plan, :invalid_payment_method) }
  let(:credit_card_plan) { build(:plan, :with_credit_card) }
  let(:bank_billet_plan) { build(:plan, :with_bank_billet) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:plan_code) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:payment_methods) }
    it { is_expected.to enumerize(:payment_methods).in(:credit_card, :bank_billet) }
    it { is_expected.to have_and_belong_to_many(:projects) }

    context 'when an invalid payment_method value is passed' do
      it 'should not be valid' do
        expect(invalid_payment_method_plan).to be_invalid
      end
    end

    context 'when the payment_method is valid' do
      context 'credit_card' do
        it 'should be valid' do
          expect(credit_card_plan).to be_valid
        end
      end

      context 'bank_billet' do
        it 'should be valid' do
          expect(bank_billet_plan).to be_valid
        end
      end
    end
  end

  describe "#active" do
    let(:active_plans) { create_list(:plan, 2) }

    subject { Plan.active }

    before { create(:plan, :inactive) }

    it "returns only the active plans" do
      expect(subject).to match_array active_plans
    end
  end
end
