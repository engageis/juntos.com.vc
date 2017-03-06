require 'rails_helper'

RSpec.describe Attachment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to :attachmentable }
  end
end
