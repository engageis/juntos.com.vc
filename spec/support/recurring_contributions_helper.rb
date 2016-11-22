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

  def build_transaction_mock
    double("Transaction", id: 10,
                          status: 'waiting_payment',
                          amount: '31000',
                          payment_method: 'credit_card')

  end

  def build_subscription_mock
    double('Subscription', id: 10,
                           payment_method: 'credit_card',
                           status: 'pending_payment',
                           plan: build_plan_mock(random_id),
                           current_transaction: build_transaction_mock)
  end
end
