function CreditCardValidator(params) {
  params = params || {};
  this.form = params.form;
  this.creditCard = params.creditCard;

  this.process = function () {
    this._hideErrors();
    this.syncCreditCard();
    return this.isValid();
  };

  this.isValid = function () {
    var valid = true;

    for (var field in this.creditCard.fieldErrors()) {
      valid = false;
      this._showError(field);
    }

    return valid;
  };

  this._showError = function (field) {
    var message = this.creditCard.fieldErrors()[field];

    this.form.$('[data-error-for="' + field + '"]').text(message)
      .removeClass('w-hidden');
  };

  this._hideErrors = function () {
    this.form.$('[data-error-for]').addClass('w-hidden');
  };

  this.syncCreditCard = function () {
    this.creditCard.cardHolderName = params.cardAttributes.cardHolderName;
    this.creditCard.cardNumber = params.cardAttributes.cardNumber;
    this.creditCard.cardExpirationMonth = params.cardAttributes.cardExpirationMonth;
    this.creditCard.cardExpirationYear = params.cardAttributes.cardExpirationYear;
    this.creditCard.cardCVV = params.cardAttributes.cardCVV;
  };
}
