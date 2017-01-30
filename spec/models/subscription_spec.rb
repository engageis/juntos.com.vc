require 'rails_helper'

RSpec.describe Subscription, type: :model do

  describe "::ACCEPTED_CHARGE_OPTIONS" do
    it "defines a constant containing the accepted charge options" do
      expect(described_class.const_defined?(:ACCEPTED_CHARGE_OPTIONS)).to be_truthy
    end
  end

  describe "associations" do
    it{ is_expected.to belong_to :user }
    it{ is_expected.to belong_to :project }
    it{ is_expected.to belong_to :plan }
  end

  describe "validations" do
    let(:plan) { create(:plan, :with_credit_card) }
    let(:unpermitted_payment_subscription) { build(:subscription, :bank_billet_payment, plan: plan) }
    let(:permitted_payment_subscription) { build(:subscription, :credit_card_payment, plan: plan) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:charging_day) }
    it { is_expected.to validate_presence_of(:payment_method) }
    it { is_expected.to validate_presence_of(:plan_id) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:project_id) }

    it { is_expected.not_to allow_value(0).for(:charging_day) }
    it { is_expected.not_to allow_value(29).for(:charging_day) }

    describe "enumerators" do
      it "should define an enum for payment_method" do
        is_expected.to define_enum_for(:payment_method)
          .with([ :credit_card, :bank_billet ])
      end

      it "should define an enum for status" do
        is_expected.to define_enum_for(:status)
          .with([ :pending_payment, :paid, :unpaid, :canceled, :waiting_for_charging_day ])
      end
    end

    context "when the subscription is made with a plan's unpermitted payment type" do
      it "should be invalid" do
        expect(unpermitted_payment_subscription).to be_invalid
      end
    end

    context "when the payment_method is permitted by the plan" do
      it "should be valid" do
        expect(permitted_payment_subscription).to be_valid
      end
    end
  end

  describe ".accepted_charge_options" do
    let(:charge_options) do
      [
        Subscription.human_attribute_name('charge_options.indefinite'),
        Subscription.human_attribute_name('charge_options.for_three_months'),
        Subscription.human_attribute_name('charge_options.for_six_months'),
        Subscription.human_attribute_name('charge_options.for_a_year')
      ]
    end

    it "should return an array matching all the ACCEPTED_CHARGE_OPTIONS's constant keys" do
      expect(described_class.accepted_charge_options.keys).to match_array charge_options
    end
  end

  describe ".charging_day_reached" do
    let(:charging_date) { DateTime.current.change(day: 15) }
    let!(:subscriptions_scheduled_for_charging_date) do
      create_list(:subscription, 4, :waiting_for_charging_day, charging_day: 15)
    end

    before do
      create_list(:subscription, 5, :unpaid, charging_day: 15)
      create_list(:subscription, 3, :waiting_for_charging_day, charging_day: 13)
      create_list(:subscription, 3, :waiting_for_charging_day, charging_day: 18)
    end

    it "returns only waiting_for_charging_day subscriptions with the charging_day equals to the current day" do
      Timecop.freeze(charging_date) do
        expect(Subscription.charging_day_reached).to match_array subscriptions_scheduled_for_charging_date
      end
    end
  end

  describe "#available_for_canceling?" do
    let(:subscription) { build(:subscription, status) }

    context "status" do
      context "when :canceled" do
        let(:status) { :canceled }

        it { expect(subscription).to_not be_available_for_canceling }
      end

      [:paid, :unpaid, :pending_payment, :waiting_for_charging_day].each do |s|
        context "when :#{s}" do
          let(:status) { s }

          it { expect(subscription).to be_available_for_canceling }
        end
      end
    end
  end

  describe ".expired" do
    subject { Subscription.expired }

    context "when subject is paid" do
      context "and expires today" do
        let!(:subscription) { create(:subscription, :paid, expires_at: Date.current) }

        it { is_expected.to contain_exactly(subscription) }
      end

      context "and expired yesterday" do
        let!(:subscription) { create(:subscription, :paid, expires_at: Date.yesterday) }

        it { is_expected.to contain_exactly(subscription) }
      end

      context "and expires tomorrow" do
        before { create(:subscription, :paid, expires_at: Date.tomorrow) }

        it { is_expected.to be_empty }
      end

      context "and has no expires_at" do
        before { create(:subscription, :paid, expires_at: nil) }

        it { is_expected.to be_empty }
      end
    end

    context "when subject is not paid" do
      before do
        create(:subscription, :unpaid, expires_at: Date.current)
        create(:subscription, :waiting_for_charging_day, expires_at: Date.current)
        create(:subscription, :pending_payment, expires_at: Date.current)
        create(:subscription, :canceled, expires_at: Date.current)
      end

      it { is_expected.to be_empty }
    end
  end
end
