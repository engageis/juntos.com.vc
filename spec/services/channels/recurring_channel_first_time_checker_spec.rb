require 'rails_helper'

RSpec.describe Channel::RecurringChannelFirstTimeChecker do
  describe ".first_time?" do
    subject { described_class.first_time?(user) }

    context "when there is a user" do
      context "when the user is owner of a recurring project" do
        let(:channel) { build(:channel, :recurring) }
        let(:project) { build(:project, channels: [channel]) }
        let(:user) { double('User', projects: [project]) }

        it { is_expected.to eq false }
      end

      context "when the user does not have recurring projects" do
        let(:user) { double('User', projects: []) }

        it { is_expected.to eq true }
      end
    end

    context "when the user does not exists" do
      let(:user) { nil }

      it { is_expected.to eq true }
    end
  end
end
