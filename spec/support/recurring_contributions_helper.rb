require 'rails_helper'
require 'rspec/mocks/standalone'

module RecurringContributionsHelper
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

  def build_transaction_mock(subscription_id = nil)
    double("Transaction", id: 10,
                          status: 'waiting_payment',
                          amount: '31000',
                          payment_method: 'credit_card',
                          subscription_id: subscription_id)

  end

  def build_subscription_mock(payment_method, plan = build_plan_mock(73197))
    double('Subscription', id: 10,
                           payment_method: payment_method,
                           status: 'pending_payment',
                           plan: plan,
                           current_period_start: Date.current,
                           current_transaction: build_transaction_mock)
  end
end

RSpec.configure do |config|
  config.include RecurringContributionsHelper
end
