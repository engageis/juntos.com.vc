App.addChild('UserBankAccountForm', {
  el: '#user-bank-account-form',

  activate: function () {
    $('.date-select select').wrap('<div class="select-wrapper">');
  },
});
