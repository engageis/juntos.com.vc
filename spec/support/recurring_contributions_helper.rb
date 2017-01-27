require 'rails_helper'
require 'rspec/mocks/standalone'

module RecurringContributionsHelper
  def mocked_plans
    (1..3).map do |plan_id|
      build_plan_mock(id: plan_id)
    end
  end

  def build_plan_mock(id:, trial_days: 0, name: 'Foo Plan')
    double("Plan", id: id,
                   name: name,
                   amount: 30,
                   payment_methods: ['boleto', 'credit_card'],
                   trial_days: trial_days)
  end

  def build_transaction_mock(subscription_id = nil, id: 10)
    double("Transaction", id: id,
                          status: 'waiting_payment',
                          amount: '31000',
                          payment_method: 'credit_card',
                          subscription_id: subscription_id)

  end

  def build_subscription_mock(payment_method, plan = build_plan_mock(id: 73197), id: 10)
    double('Subscription', id: id,
                           payment_method: payment_method,
                           status: 'pending_payment',
                           plan: plan,
                           current_period_start: Date.current,
                           current_transaction: build_transaction_mock)
  end

  def pagarme_resource_class(type)
    case type
    when :plan
      PagarMe::Plan
    when :subscription
      PagarMe::Subscription
    when :transaction
      PagarMe::Transaction
    end
  end

  def pagarme_mock(type)
    send("build_#{type}_mock", id: 10)
  end
end

RSpec.configure do |config|
  config.include RecurringContributionsHelper
end
