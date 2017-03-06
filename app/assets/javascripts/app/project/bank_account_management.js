App.addChild('BankAccountAssociate', _.extend({
  el: '#bank-account-associate',

  events: {
    'click #new-account': 'showNewBankAccountForm',
    'click #close-form':  'hideNewBankAccountForm',
    'ajax:success':       'onAjaxPostSuccess',
    'ajax:error':         'onAjaxError',
  },

  activate: function () {
    this.scroller = new ScrollerComponent();
    this.$bankAccountForm = this.$('#user-bank-account-form');
    this.$errorCard = this.$('.card-error');
    this.$selectAccountId = this.$('#select-account-id');
    this.$associationNotification = this.$('.notification');
    this.$associationButton = this.$('#association-button');
  },

  onAjaxPostSuccess: function (e, data) {
    if ($(e.target).is('#associate-project-bank-account')) {
      this.$associationNotification.find('.success')
        .removeClass('w-hidden');
    } else {
      this.hideErrorCard();
      this.appendNewAccount(data);
      this.$associationButton.prop('disabled', false);
      this.hideNewBankAccountForm();
    }
  },

  showNewBankAccountForm: function () {
    this.$bankAccountForm.closest('.content').removeClass('w-hidden');
  },

  hideNewBankAccountForm: function () {
    this.$bankAccountForm.closest('.content').addClass('w-hidden');
  },

  appendNewAccount: function (bankAccount) {
    this.$selectAccountId.append(
      App.templates.bankAccountOption({
        id: bankAccount.id,
        name: bankAccount.bank.name,
      })
    );
  },
}, new RemoteRequestsForm($('#bank-account-associate'))));
