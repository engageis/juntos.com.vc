require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:transaction_code) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:payment_method) }
    it { is_expected.to validate_presence_of(:subscription_id) }

    it { is_expected.to enumerize(:payment_method).in(:credit_card, :bank_billet) }
    it { is_expected.to enumerize(:status).in(:processing, :authorized, :paid,
                                              :refunded, :waiting_payment,
                                              :pending_payment, :refused) }
  end

  describe 'associations' do
    it{ is_expected.to belong_to :subscription }
    it{ is_expected.to have_one(:project).through(:subscription) }
  end
end
