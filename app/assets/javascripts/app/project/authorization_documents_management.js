App.addChild('AuthorizationDocumentsManagement', _.extend({
  el: '.authorization-documents-list',

  events: {
    'click #open-form':  'showForm',
    'click #close-form': 'hideForm',
    'ajax:success':      'onAjaxSuccess',
    'ajax:error':        'onAjaxError',
  },
}, new RemoteRequestsForm($('#user-authorization-documents-form'))));
