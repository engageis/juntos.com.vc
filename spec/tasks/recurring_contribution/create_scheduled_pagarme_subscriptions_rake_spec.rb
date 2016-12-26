require 'rails_helper'
require 'rake'

RSpec.describe "Subscriptions" do
  before do
    Rake.application.rake_require 'tasks/cron'
    Rake::Task.define_task(:environment)
  end

  describe "recurring_contribution:create_scheduled_pagarme_subscriptions" do
    let(:run_rake_task) do
      Rake::Task['recurring_contribution:create_scheduled_pagarme_subscriptions'].reenable
      Rake.application.invoke_task 'recurring_contribution:create_scheduled_pagarme_subscriptions'
    end

    it "calls the RecurringContribution::ChargingSubscriptionWorker" do
      expect(RecurringContribution::ChargingSubscriptionWorker)
        .to receive(:perform_async).at_most(:twice)
      run_rake_task
    end
  end
end
