function SubViewsManager(args) {
  this.render = function (subViewRoute) {
    var $routeElement = args.parent.find('#' + subViewRoute);
    var subView = $routeElement.data('target');

    this.showSubView(subView);
  };

  this.showSubView = function (subView) {
    args.parent.find(args.subViewsContainer).addClass('w-hidden');
    args.parent.find(subView).toggleClass('w-hidden');
  };
}
