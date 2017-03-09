var RemoteRequestsForm = function (el) {
  this.$el = el;
  this.$errorCard = this.$el.find('.card-error');

  this.onAjaxSuccess = function (e, data) {
    this.$el.find('.success')
      .removeClass('w-hidden');
  };

  this.onAjaxError = function (e, data) {
    var response = jQuery.parseJSON(data.responseText);
    var scroller = new ScrollerComponent();

    this.showErrorCard(response.errors);
    scroller.scrollTo(this.$errorCard);
  };

  this.showErrorCard = function (message) {
    this.$errorCard.removeClass('w-hidden');
    this.appendErrorMessage(message);
  };

  this.hideErrorCard = function () {
    this.$errorCard.addClass('w-hidden');
  };

  this.appendErrorMessage = function (message) {
    this.$errorCard.find('.message').empty().append(message);
  };

  this.showForm = function (e) {
    var targetForm = $(e.target).data('target');
    var $form = $(targetForm);

    $form.closest('.content').removeClass('w-hidden');
  };

  this.hideForm = function (e) {
    var $form = $(e.target).closest('form');

    $form.closest('.content').addClass('w-hidden');
  };
};
