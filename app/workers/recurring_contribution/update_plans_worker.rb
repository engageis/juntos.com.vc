class RecurringContribution::UpdatePlansWorker
  include Sidekiq::Worker
  sidekiq_options retry: 2

  def perform
    RecurringContribution::UpdatePlans.call
  end
end
