App.addChild('ReviewForm', _.extend({
  el: 'form#review_form',

  events: {
    'blur input' : 'checkInput',
    'change #contribution_country_code' : 'onCountryChange',
    'change #contribution_anonymous' : 'toggleAnonymousConfirmation',
    'click #next-step' : 'onNextStepClick',
    'click [data-recurring=true]' : 'sendRecurringContribution'
  },

  sendRecurringContribution: function (e) {
    e.preventDefault();

    PagarMe.encryption_key = $(e.currentTarget).data('pagarme-encryption');

    this._hideErrors();

    this.creditCard = new PagarMe.creditCard();
    this._sync();

    if (! this._hasErrors()) {
      var _this = this;

      this.creditCard.generateHash(function (hash) {
        _this.$el.find('[data-card-info]').attr('disabled', true);
        _this.$el.append('<input type="hidden" name="payment_card_hash" value="' +hash+ '">');
        _this.$el.submit();
      });
    }
  },

  _sync: function () {
    this.creditCard.cardHolderName = this.$('[data-payment-card-holder-name]').val();
    this.creditCard.cardNumber = this.$('[data-payment-card-number]').val();
    this.creditCard.cardExpirationMonth = this.$('[data-payment-card-expiration-month]').val();
    this.creditCard.cardExpirationYear = this.$('[data-payment-card-expiration-year]').val();
    this.creditCard.cardCVV = this.$('[data-payment-card-cvv]').val();
  },

  _hasErrors: function () {
    var hasErrors = false;

    for (var field in this.creditCard.fieldErrors()) {
      hasErrors = true;
      this._showError(field);
    }

    return hasErrors;
  },

  _showError: function (field) {
    var message = this.creditCard.fieldErrors()[field];

    this.$('[data-error-for="' +field+ '"]').text(message)
      .removeClass('w-hidden');
  },

  _hideErrors: function () {
    this.$('[data-error-for]').addClass('w-hidden');
  },

  validateMasked: function(inputField) {
    var $this = $(inputField);
    var validInput = true;
    var mask = $this.data('mask');
    if(mask){
      // just numbers
      if($this.val() === "" || !/.*\?.*/gi.test(mask) && /.*_.*/gi.test($this.val())){
        validInput = false;
      }
      // with optional numbers (?)
      if($this.val() === "" || /.*\?.*/gi.test(mask) && /.*_.*_.*/gi.test($this.val())){
        validInput = false;
      }
    }
    if(!validInput) {
      $this.trigger('invalid');
    }

    return validInput
  },

  validateZipAndPhone: function() {
    return (this.validateMasked(this.$phone) && this.validateMasked(this.$zip));
  },

  onNextStepClick: function(){
    if(this.validate() && this.validateZipAndPhone()){
      if(this.updateContribution()) {
        this.$errorMessage.hide();
        this.$('#next-step').hide();
        this.parent.payment.show();
      }
    }
    else{
      this.$errorMessage.slideDown('slow');
    }
  },

  toggleAnonymousConfirmation: function(){
    this.$('#anonymous-confirmation').slideToggle('slow');
  },

  onCountryChange: function(){
    this.loadStates();

    if(this.$country.val() == 'BR'){
      this.nationalAddress();
    }
    else{
      this.internationalAddress();
    }
  },

  loadStates: function(){
    var url = '/countries/' + this.$country.val() + '/states';
    var state = this.$state;
    var stateVal = state.val();
    this.clearStates();
    
    $.get(url, function(data){
      $.each(data, function(index, value){
        var selected = (stateVal == value[0]);
        state.append(new Option(value[1], value[0], false, selected));
      }); 
    }); 
  },

  clearStates: function(){
    this.$state.html('<option value="">-------</option>');
  },

  unMaskFields: function(){
    this.$phone.unmask();
    this.$zip.unmask();
  },

  maskFields: function(){
    this.$phone.mask('(99)9999-9999?9');
    this.$zip.mask('99999-999');
  },

  nationalAddress: function(){
    this.parent.payment.loadPaymentChoicesPerNationality(true);
    this.makeFieldsRequired();
    this.maskFields();
  },

  internationalAddress: function(){
    this.parent.payment.loadPaymentChoicesPerNationality(false);
    this.makeFieldsOptional();
    this.unMaskFields();
  },

  makeFieldsRequired: function(){
    this.$('[data-required-in-brazil]').prop('required', 'required');
    this.$('[data-required-in-brazil]').parent().removeClass('optional').addClass('required');
  },

  makeFieldsOptional: function(){
    this.$('[data-required-in-brazil]').prop('required', false);
    this.$('[data-required-in-brazil]').parent().removeClass('required').addClass('optional');
  },

  acceptTerms: function(){
    if(this.validate()){
      $('#payment').show();
      this.updateContribution();
    } else {
      return false;
    }
  },

  activate: function(){
    this.$country = this.$('#contribution_country_code');
    this.$state = this.$('#contribution_address_state');
    this.$phone = this.$('#contribution_address_phone_number');
    this.$zip = this.$('#contribution_address_zip_code');

    this.$errorMessage = this.$('#error-message');
    this.setupForm();
    this.onCountryChange();
  },

  onUserDocumentKeyup: function(e) {
    var $documentField = $(e.currentTarget);
    var documentNumber = $documentField.val();
    $documentField.prop('maxlength', 18);
    var resultCpf = this.validateCpf(documentNumber);
    var resultCnpj = this.validateCnpj(documentNumber.replace(/[\/.\-\_ ]/g, ''));
    var numberLength = documentNumber.replace(/[.\-\_ ]/g, '').length
    if(numberLength > 10) {
     if($documentField.attr('id') != 'payment_card_cpf'){
         if(numberLength == 11) {$documentField.mask('999.999.999-99?999'); }//CPF
         else if(numberLength == 14 ){$documentField.mask('99.999.999/9999-99');}//CNPJ
         if(numberLength != 14 || numberLength != 11){ $documentField.unmask()}
        }

     if(resultCpf || resultCnpj) {
        $documentField.addClass('ok').removeClass('error');
      } else {
        $documentField.addClass('error').removeClass('ok');
      }
    }
     else{
        $documentField.addClass('error').removeClass('ok');
     }
  },

  updateContribution: function(){
    var contribution_data = {
      anonymous: this.$('#contribution_anonymous').is(':checked'),
      country_code: this.$('#contribution_country_code').val(),
      payer_name: this.$('#contribution_full_name').val(),
      payer_email: this.$('#contribution_email').val(),
      payer_document: this.$('#contribution_payer_document').val(),
      address_street: this.$('#contribution_address_street').val(),
      address_number: this.$('#contribution_address_number').val(),
      address_complement: this.$('#contribution_address_complement').val(),
      address_neighbourhood: this.$('#contribution_address_neighbourhood').val(),
      address_zip_code: this.$('#contribution_address_zip_code').val(),
      address_city: this.$('#contribution_address_city').val(),
      address_state: this.$('#contribution_address_state').val(),
      address_phone_number: this.$('#contribution_address_phone_number').val(),
      partner_indication: this.$('#contribution_partner_indication').prop('checked')
    };

    if(contribution_data.address_zip_code !== '' && contribution_data.address_phone_number !== '') {
      $.post(this.$el.data('update-info-path'), {
        _method: 'put',
        contribution: contribution_data
      });
      return true
    } else {
      return false
    }
  },

  validateCpf: function(cpfString){
    var product = 0, i, digit;
    cpfString = cpfString.replace(/[.\-\_ ]/g, '');
    var aux = Math.floor(parseFloat(cpfString) / 100);
    var cpf = aux * 100;
    var quotient;

    for(i=0; i<=8; i++){
      product += (aux % 10) * (i+2);
      aux = Math.floor(aux / 10);
    }
    digit = product % 11 < 2 ? 0 : 11 - (product % 11);
    cpf += (digit * 10);
    product = 0;
    aux = Math.floor(cpf / 10);
    for(i=0; i<=9; i++){
      product += (aux % 10) * (i+2);
      aux = Math.floor(aux / 10);
    }
    digit = product % 11 < 2 ? 0 : 11 - (product % 11);
    cpf += digit;
    return parseFloat(cpfString) === cpf;
  },

  validateCnpj: function(cnpj) {
    var numeros, digitos, soma, i, resultado, pos, tamanho, digitos_iguais;
    digitos_iguais = 1;
    if (cnpj.length < 14 && cnpj.length < 15)
      return false;
    for (i = 0; i < cnpj.length - 1; i++)
    if (cnpj.charAt(i) != cnpj.charAt(i + 1))
      {
        digitos_iguais = 0;
        break;
      }
      if (!digitos_iguais)
        {
          tamanho = cnpj.length - 2
          numeros = cnpj.substring(0,tamanho);
          digitos = cnpj.substring(tamanho);
          soma = 0;
          pos = tamanho - 7;
          for (i = tamanho; i >= 1; i--)
          {
            soma += numeros.charAt(tamanho - i) * pos--;
            if (pos < 2)
              pos = 9;
          }
          resultado = soma % 11 < 2 ? 0 : 11 - soma % 11;
          if (resultado != digitos.charAt(0))
            return false;
          tamanho = tamanho + 1;
          numeros = cnpj.substring(0,tamanho);
          soma = 0;
          pos = tamanho - 7;
          for (i = tamanho; i >= 1; i--)
          {
            soma += numeros.charAt(tamanho - i) * pos--;
            if (pos < 2)
              pos = 9;
          }
          resultado = soma % 11 < 2 ? 0 : 11 - soma % 11;
          if (resultado != digitos.charAt(1))
            return false;
          return true;
        }
        else
          return false;
  }

}, Skull.Form));
