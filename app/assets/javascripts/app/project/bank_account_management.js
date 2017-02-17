App.addChild('BankAccountAssociate', {
  el: '#bank-account-associate',

  events: {
    'click #new-account': 'showNewBankAccountForm',
    'click #close-form':  'hideNewBankAccountForm',
    'click #submit-form': 'createBankAccount',
    'ajax:success':       'onPostSuccess',
    'ajax:error':         'onPostError',
  },

  activate: function () {
    this.scroller = new ScrollerComponent();
    this.$bankAccountForm = this.$('#user-bank-account-form');
    this.$errorCard = this.$('.card-error');
    this.$selectAccountId = this.$('#select-account-id');
    this.$associationNotification = this.$('.notification');
    this.$associationButton = this.$('#association-button');
  },

  onPostSuccess: function (e, data) {
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

  onPostError: function (e, data) {
    if ($(e.target).is('#associate-project-bank-account')) {
      this.$associationNotification.find('.fail')
        .removeClass('w-hidden');
    } else {
      this.showErrorCard(data.responseJSON.errors);
      this.scroller.scrollTo(this.$errorCard);
    }
  },

  showNewBankAccountForm: function () {
    this.$bankAccountForm.closest('.content').removeClass('w-hidden');
  },

  hideNewBankAccountForm: function () {
    this.$bankAccountForm.closest('.content').addClass('w-hidden');
  },

  showErrorCard: function (message) {
    this.$errorCard.removeClass('w-hidden');
    this.appendErrorMessage(message);
  },

  hideErrorCard: function () {
    this.$errorCard.addClass('w-hidden');
  },

  appendNewAccount: function (bankAccount) {
    this.$selectAccountId.append(
      App.templates.bankAccountOption({
        id: bankAccount.id,
        name: bankAccount.bank.name,
      })
    );
  },

  appendErrorMessage: function (message) {
    this.$errorCard.find('.message').empty().append(message);
  },
});
