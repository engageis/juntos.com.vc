class Reports::SubscriptionWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(project_id)
    subscriptions = Subscription.available.by_project(project_id)

    report_file_path = SubscriptionCollectionReport.new(subscriptions, project_id).export!

    SubscriptionReport.create(attachment: File.open(report_file_path), project_id: project_id)
  end
end
