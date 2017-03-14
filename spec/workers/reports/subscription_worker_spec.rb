require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe Reports::SubscriptionWorker do
  let(:project)       { create(:project) }
  let(:project_id)    { project.id }
  let(:subscriptions) { Subscription.all }
  let(:subscription_collection_report) { instance_double(SubscriptionCollectionReport) }
  let(:file_path) { "file_path" }
  let(:file)      { instance_double(File) }

  describe '.perform_async' do
    before do
      Sidekiq::Testing.inline!

      allow(Subscription).to receive(:available).and_return(subscriptions)
      allow(Subscription).to receive(:by_project).with(project_id).and_return(subscriptions)
      allow(SubscriptionCollectionReport).to receive(:new)
        .with(subscriptions, project_id)
        .and_return(subscription_collection_report)
      allow(subscription_collection_report).to receive(:export!).and_return(file_path)
      allow(File).to receive(:open).and_return(file)
      allow(SubscriptionReport).to receive(:create)

      Reports::SubscriptionWorker.perform_async(project_id)
    end

    it { expect(Subscription).to have_received(:available).once }
    it { expect(Subscription).to have_received(:by_project).once }
    it { expect(SubscriptionCollectionReport).to have_received(:new).with(subscriptions, project_id).once }
    it { expect(subscription_collection_report).to have_received(:export!).once }
    it { expect(SubscriptionReport).to have_received(:create).with(attachment: file, project_id: project_id).once }
  end
end
