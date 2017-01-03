App.addChild('Project', _.extend({
  el: '.content[data-action="show"][data-controller-name="projects"]',

  events: {
    'click #toggle_warning a' : 'toggleWarning',
    'click a#embed_link' : 'toggleEmbed'
  },

  activate: function(){
    this.$warning = this.$('#project_warning_text');
    this.$embed= this.$('#project_embed');
    this.route('about');
    this.route('basics');
    this.route('dashboard_project');
    this.route('dashboard_project_plans');
    this.route('dashboard_rewards');
    this.route('dashboard_subgoals');
    this.route('posts');
    this.route('rewards');
    this.route('contributions');
    this.route('comments');
    this.route('edit');
    this.route('reports');
    this.route('project_metrics');
    this.route('project_reports');
    this.route('project_bank_info');
  },

  toggleWarning: function(){
    this.$warning.slideToggle('slow');
    return false;
  },

  toggleEmbed: function(){
    this.loadEmbed();
    this.$embed.slideToggle('slow');
    return false;
  },

  followRoute: function(name){
    var $tab = this.$('nav a[href="' + window.location.hash + '"]');
    if($tab.length > 0){
      this.onTabClick({ currentTarget: $tab });

      var links = ['project_metrics_link', 'project_reports_link', 'basics_link', 'dashboard_project_link', 'dashboard_project_plans_link', 'dashboard_rewards_link', 'dashboard_subgoals_link', 'project_bank_info_link'];

      $('[data-project-owner-sidebar]').toggle( ($.inArray($tab.prop('id'), links) == -1) );
    }
  },

  loadEmbed: function() {
    var that = this;

    if(this.$embed.find('.loader').length > 0) {
      $.get(this.$embed.data('path')).success(function(data){
        that.$embed.html(data);
      });
    }
  }
}, Skull.Tabs));

$(document).ready(function() {
  if ($('[data="select2"]').length > 0) { $('[data="select2"]').select2(); }
});
