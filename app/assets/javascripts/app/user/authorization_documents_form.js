App.addChild('UserAuthorizationDocumentsForm', _.extend({
  el: '#user-authorization-documents-form',

  events: {
    'ajax:success': 'onAjaxSuccess',
    'ajax:error':   'onAjaxError',
  },
}, new RemoteRequestsForm($('#user-authorization-documents-form'))));
