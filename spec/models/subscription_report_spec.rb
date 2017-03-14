require 'rails_helper'

RSpec.describe SubscriptionReport, type: :model do
  describe "associations" do
    it { is_expected.to belong_to :project }
  end
end
