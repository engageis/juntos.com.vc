App.addChild('DashboardDocuments', _.extend({
  el: '.user-authorization-documents',

  events: {
    'click .dashboard-menu .link': 'onSelectTab',
  },

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

  onSelectTab: function (e) {
    $('.dashboard-menu .selected').removeClass('selected');
    $(e.target).closest('div').toggleClass('selected');
  },
}, Skull.Tabs));
