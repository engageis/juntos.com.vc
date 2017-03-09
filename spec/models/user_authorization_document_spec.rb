require 'rails_helper'

RSpec.describe UserAuthorizationDocument do
  describe "validations" do
    describe "attachment validation" do
      let(:user) { create(:user) }
      let(:user_authorization_document) do
        described_class.new(
          authable: user,
          category: category,
          attachment: attachment,
          expires_at: Date.current
        )
      end

      subject { user_authorization_document }

      context "when the attachment url is present" do
        let(:category) { :cnpj_card }
        let(:attachment) { build(:attachment, url: 'http://valid.com') }

        it { is_expected.to be_valid }
      end

      context "when the attachment url is not present" do
        let(:attachment) { build(:attachment, url: '') }

        context "and the document's category is obligatory" do
          let(:category) { :cnpj_card }

          it { is_expected.to be_invalid }
        end

        context "and the document's category is optional" do
          let(:category) { :certificates }

          it { is_expected.to be_valid }
        end
      end
    end
  end
end
