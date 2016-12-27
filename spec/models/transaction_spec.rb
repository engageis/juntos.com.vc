require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:transaction_code) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:payment_method) }
    it { is_expected.to validate_presence_of(:subscription_id) }

    describe "enumerators" do
      it "should define an enum for payment_method" do
        is_expected.to define_enum_for(:payment_method)
          .with([ :credit_card, :bank_billet ])
      end

      it "should define an enum for status" do
        is_expected.to define_enum_for(:status)
          .with([ :pending_payment, :processing, :authorized, :paid, :refunded, :waiting_payment, :refused ])
      end
    end
  end

  describe 'associations' do
    it{ is_expected.to belong_to :subscription }
    it{ is_expected.to have_one(:project).through(:subscription) }
  end
end
