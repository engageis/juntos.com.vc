App.addChild('Payment', _.extend({
  el: '#payment-engines',

  events: {
    'click .nav-tab' : 'onClickPayment'
  },

  onClickPayment: function(event){
    this.$('.tab-loader img').show();
    this.onTabClick(event);
  },

  activate: function(){
  },

  show: function(){
    this.$el.slideDown('slow');
  },

  updatePaymentMethod: function() {
    var $selected_tab = this.$('.nav-tab.selected');
    $.ajax({
      url: this.$el.data('update-info-path'),
      type: 'PUT',
      data: { contribution: { payment_method: $selected_tab.prop('id') } }
    });
  },

  hideNationalPayment: function() {
    this.$('#MoIP').hide();
    this.$('#MoIP_payment').hide();
  },

  showNationalPayment: function() {
    this.$('#MoIP').show();
    this.$('#MoIP_payment').show();
    this.$('#PayPal_payment').hide();
  },

  selectInternationalPayment: function() {
    this.onTabClick({currentTarget: this.$('#PayPal')});
  },

  selectNationalPayment: function() {
    this.onTabClick({currentTarget: this.$('#MoIP')});
  },

  loadPaymentChoicesPerNationality: function(national) {
    if(national) {
      this.showNationalPayment();
      this.selectNationalPayment();
    } else {
      this.hideNationalPayment();
      this.selectInternationalPayment();
    }

    this.on('selectTab', this.updatePaymentMethod);
  }
}, Skull.Tabs));
