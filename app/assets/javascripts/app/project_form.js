App.addChild('ProjectForm', _.extend({
  el: 'form#project_form',

  events: {
    'blur input' : 'checkInput',
  },

  activate: function(){
    this.setupForm();
  }

}, Skull.Form));

// Put subview here to avoid dependency issues

App.views.ProjectForm.addChild('VideoUrl', _.extend({
  el: 'input#project_video_url',

  events: {
    'timedKeyup' : 'checkVideoUrl'
  },

  checkVideoUrl: function(){
    var that = this;
    $.get(this.$el.data('path') + '?url=' + encodeURIComponent(this.$el.val())).success(function(data){
      if(!data || !data.provider){
        that.$el.trigger('invalid');
      }
    });
  },

  activate: function(){
    this.setupTimedInput();
  }
}, Skull.TimedInput));

App.views.ProjectForm.addChild('Permalink', _.extend({
  el: 'input#project_permalink',

  events: {
    'timedKeyup' : 'checkPermalink'
  },

  checkPermalink: function(){
    var that = this;
    if(this.re.test(this.$el.val())){
      $.get('/pt/' + this.$el.val()).complete(function(data){
        if(data.status != 404){
          that.$el.trigger('invalid');
        }
      });
    }
  },

  activate: function(){
    this.re = new RegExp(this.$el.prop('pattern'));
    this.setupTimedInput();
  }
}, Skull.TimedInput));

App.addChild('RemoveProjectImage', {
  el: 'a.js-remove_project_image',

  events: {
    'click': 'removeProjectImage'
  },

  removeProjectImage: function(event){
    event.preventDefault();
    var removeProjectImage = this.el;
    var parent = $(removeProjectImage).parents('.w-col.thumbnail-card');
    parent.find('.thumbnail').remove();
    parent.find('input[name*="_destroy"]').val('true');
    $('.js-btn-submit').click();
    return false;
  }

});

App.addChild('RemoveProjectPartner', {
  el: 'a.js-remove_project_partner',

  events: {
    'click': 'removeProjectPartner'
  },

  removeProjectPartner: function(event){
    event.preventDefault();
    var removeProjectPartner = this.el;
    var parent = $(removeProjectPartner).parents('.w-col.thumbnail-card');
    parent.find('.thumbnail').remove();
    parent.find('input[name*="_destroy"]').val('true');
    $('.js-btn-submit').click();
    return false;
  }

});

App.views.ProjectForm.addChild('ProjectGalleryUploader', {
  el: '[data-project-gallery-uploader]',
  submitButton: $('.js-btn-submit'),
  template: _.template($('[data-thumbnail-card-template]').html()),

  events: {
    's3_uploads_start': 'uploadStarted',
    's3_upload_complete': 'uploadComplete',
    's3_uploads_complete': 'allUploadsComplete'
  },

  activate: function () {
    this.$el.find('[data-s3-uploader]').S3Uploader();
    this.thumbGallery = this.$el.find('[data-thumbnail-gallery]');
  },

  uploadStarted: function (e) {
    this.submitButton.attr('disabled', true);
  },

  allUploadsComplete: function (e) {
    this.submitButton.attr('disabled', false);
  },

  uploadComplete: function (e, content) {
    var image = {
      caption: '',
      url: content.url
    };

    this.thumbGallery.append(this.template({image: image}));
  }
});
