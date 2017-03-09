require 'rails_helper'

RSpec.describe User::AuthorizationDocumentsValidator do
  describe "validations" do
    describe "authorization documents validation" do
      let(:user) { create(:user) }
      let(:valid_attachment) { build(:attachment, url: 'http://foo.valid.com') }
      let(:invalid_attachment) { build(:attachment, url: '') }
      let(:legal_entity_required_documents) { User::LEGAL_ENTITY_AUTHORIZATION_DOCUMENTS }
      let(:user_documents_validator) do
        described_class.new(user: user)
      end

      subject { user_documents_validator }

      context "when all required documents were sent" do
        before do
          last_year_activities_report = legal_entity_required_documents.delete(:last_year_activities_report)

          user.authorization_documents.build(
            category: last_year_activities_report,
            attachment: invalid_attachment,
            expires_at: Date.current
          )

          legal_entity_required_documents.each do |doc|
            user.authorization_documents.build(category: doc, attachment: valid_attachment, expires_at: Date.current)
          end
        end

        it { is_expected.to be_valid }
      end

      context "when just one of the required documents was not sent" do
        before do
          cnpj_card = legal_entity_required_documents.delete(:cnpj_card)

          user.authorization_documents.build(category: cnpj_card, attachment: invalid_attachment, expires_at: Date.current)

          legal_entity_required_documents.each do |doc|
            user.authorization_documents.build(category: doc, attachment: valid_attachment, expires_at: Date.current)
          end
        end

        it { is_expected.to be_invalid }
      end
    end
  end
end
