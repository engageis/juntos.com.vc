require 'rails_helper'

RSpec.describe CreateMultiCategoriesChannel do
  describe "#call" do
    let! (:channel) { FactoryGirl.create(:channel) }
    let! (:category) { FactoryGirl.create(:category) }

    subject { CreateMultiCategoriesChannel.new(category, channel) }

    it "Add a category into a channel" do
      subject.call
      expect(channel.categories.reload.count).to be(1)
    end
  end
end
