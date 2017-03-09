class AuthorizationDocumentDecorator < Draper::Decorator
  delegate_all

  def visualization
    return document_link if source.uploaded?

    not_sent_message
  end

  private

  def document_link
    h.content_tag(:a, href: source.attachment.url, class: 'link default', target: '_blank') do
      h.content_tag(:span, I18n.t('users.required_documents.list.sent')) +
      h.content_tag(:i, nil, class: 'fa fa-eye u-marginleft-5')
    end
  end

  def not_sent_message
    h.content_tag(:span, I18n.t('users.required_documents.list.not_sent'), class: 'not-sent bold')
  end
end
