App.addChild('DashboardDocuments', _.extend({
  el: '.user-authorization-documents',

  activate: function () {
    this.subViewsManager = new SubViewsManager({
      parent: this.$el,
      subViewsContainer: '.content',
    });

    this.route('bank-accounts');
    this.route('authorization-documents');
    this.subViewsManager.render('authorization-documents');
  },

  followRoute: function (subViewRoute) {
    this.subViewsManager.render(subViewRoute);
  },
}, Skull.Tabs));
