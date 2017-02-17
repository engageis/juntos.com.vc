function ScrollerComponent() {
  this.scrollTo = function (target) {
    if (target.length) {
      $('html, body').animate({
        scrollTop: target.offset().top,
      }, 1000);
      return false;
    }
  };
}
