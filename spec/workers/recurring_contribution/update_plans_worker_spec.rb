require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe RecurringContribution::UpdatePlansWorker do
  subject { RecurringContribution::UpdatePlansWorker }

  it "retries the job processing at most 2 times" do
    expect(subject.get_sidekiq_options['retry']).to eq 2
  end

  describe "#perform_async" do
    it "calls the RecurringContribution::UpdatePlans service" do
      expect(RecurringContribution::UpdatePlans)
        .to receive(:call)

      Sidekiq::Testing.inline! do
        subject.perform_async
      end
    end
  end
end
