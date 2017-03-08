require 'rails_helper'

RSpec.describe UserAuthorizationDocument, type: :model do
  describe "validations" do
    describe "attachment validation" do
      let(:user) { create(:user) }
      let(:user_authorization_document) do
        build(:user_authorization_document,
          authable: user,
          category: category,
          attachment: attachment
        )
      end

      subject { user_authorization_document }

      context "when the category's document requires an attachment" do
        let(:category) { :cnpj_card }

        context "and the attachment is present" do
          let(:attachment) { build(:attachment, url: 'http://valid.com') }

          it { is_expected.to be_valid }
        end

        context "and the attachment is empty" do
          let(:attachment) { build(:attachment, url: '') }

          it { is_expected.to be_invalid }
        end
      end

      context "when the category's document does not require an attachment" do
        let(:category) { :certificates }

        context "and the attachment is present" do
          let(:attachment) { build(:attachment, url: 'http://valid.com') }

          it { is_expected.to be_valid }
        end

        context "and the attachment is empty" do
          let(:attachment) { build(:attachment, url: 'http://valid.com') }

          it { is_expected.to be_valid }
        end
      end
    end
  end
end
