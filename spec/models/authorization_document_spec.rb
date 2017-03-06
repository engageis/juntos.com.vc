require 'rails_helper'

RSpec.describe AuthorizationDocument, type: :model do
  describe "associations" do
    it { is_expected.to belong_to :authable }
    it { is_expected.to have_one :attachment }
  end

  describe "validations" do
    let(:attachment) { build(:attachment, url: 'http://foo.com') }
    let(:user) { create(:user) }
    subject { build(:authorization_document, attachment: attachment, authable: user) }

    it { is_expected.to validate_presence_of(:expires_at) }

    describe "attachment validation" do
      before { subject.save }

      context "when the attachment has a valid url" do
        let(:attachment) { build(:attachment, url: 'http://foo.com') }

        it { is_expected.to be_valid }
      end

      context "when the attachment url is empty" do
        let(:attachment) { build(:attachment, url: '') }

        it "must be invalid" do
          expect(subject).to_not be_valid
        end
      end
    end

    describe "enumerators" do
      let(:expected_enums) do
        [
          :uncategorized,
          :bank_authorization,
          :organization_authorization,
          :bylaw_registry,
          :last_general_meeting_minute,
          :fiscal_council_report,
          :directory_proof,
          :last_mandate_balance,
          :cnpj_card,
          :certificates,
          :last_year_activities_report,
          :organization_current_plan,
          :federal_tributes_certificate,
          :federal_court_debt_certificate,
          :manager_id
        ]
      end

      it "defines an enum for description" do
        is_expected.to define_enum_for(:category).with(expected_enums)
      end
    end
  end
end
