require 'rails_helper'

RSpec.describe AuthorizationDocument, type: :model do
  describe "associations" do
    it { is_expected.to belong_to :bank_account }
    it { is_expected.to have_one :attachment }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:expires_at) }

    describe "enumerators" do
      it "defines an enum for description" do
        is_expected.to define_enum_for(:category)
          .with([ :uncategorized, :bank_authorization, :organization_authorization ])
      end
    end
  end
end
