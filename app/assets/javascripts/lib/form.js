Skull.Form = {
  checkInput: function(event){
    var $this = $(event.currentTarget);
    var validInput = true;
    var mask = $this.data('mask');
    if(mask){
      // just numbers
      if(!/.*\?.*/gi.test(mask) && /.*_.*/gi.test($this.val())){
        validInput = false;
      }
      // with optional numbers (?)
      if(/.*\?.*/gi.test(mask) && /.*_.*_.*/gi.test($this.val())){
        validInput = false;
      }
    }
    if(!validInput) {
      $this.trigger('invalid');
    }

    if(event.currentTarget.checkValidity() && validInput){
      var $target = this.$(event.currentTarget);
      $target.removeClass("error");
      this.$('[data-error-for=' + $target.prop('id') + ']').hide();
    }
  },

  setupForm: function(){
    this.$('input, select').on('invalid', this.invalid);
  },

  invalid: function(event){
    var $target = this.$(event.currentTarget);
    $target.addClass("error");
    this.$('[data-error-for=' + $target.prop('id') + ']').show();
  },

  validate: function(){
    var valid = true;
    this.$('input:visible, select:visible').each(function(){
      valid = this.checkValidity() && valid;
    });

    this.$('input.error:visible:first').select();
    return valid;
  }
};
