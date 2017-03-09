require 'rails_helper'

RSpec.describe AuthorizationDocumentDecorator do
  describe ".visualization" do
    let(:authorization_document) { build(:authorization_document, attachment: attachment).decorate }

    subject { authorization_document.visualization}

    context "when the document has an attachment" do
      let(:attachment) { build(:attachment) }
      let(:view_document_message) { I18n.t('users.required_documents.list.sent') }

      it "returns a link tag for the document visualization" do
        expect(subject).to have_tag('a', text: view_document_message)
      end
    end

    context "when the document does not have an attachment" do
      let(:attachment) { build(:attachment, :with_empty_url) }
      let(:not_sent_message) { I18n.t('users.required_documents.list.not_sent') }

      it "returns not sent message" do
        expect(subject).to have_tag('span', text: not_sent_message)
      end
    end
  end
end
