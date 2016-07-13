$(document).ready(function() {
  var absolute_height = 0;
  $(".one-subgoal").each(function(i, e) {
    var eheight = $(e).innerHeight();
    if (eheight > absolute_height) {
      absolute_height = eheight;
    }
  });
  $(".project-progress-stats").css("margin-bottom", (absolute_height - 20) + "px");
});
