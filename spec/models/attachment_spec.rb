require 'rails_helper'

RSpec.describe Attachment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to :attachmentable }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:url) }
  end
end
