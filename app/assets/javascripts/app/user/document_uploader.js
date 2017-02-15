App.addChild('DocumentUploader', {
  el: '[data-document-uploader]',

  events: {
    's3_upload_complete': 'updateUploadField'
  },

  activate: function () {
    this.$el.find('[data-s3-uploader]').S3Uploader();
  },

  updateUploadField: function (e, content) {
    var $fileInput = $(e.currentTarget).find('[type="file"]');

    $fileInput.prop('disabled', true);
    $fileInput.after('<i class="fa fa-paperclip" aria-hidden="true">' + content.filename + '</i>');
    $(e.currentTarget).find('[data-document-field]').val(content.url);
  },
});
