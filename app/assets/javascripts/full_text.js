$(document).ready(function() {
  $('body').on('click', '.load-more', function(e) {
    $.ajax({
      url: this.href + "&partial=true",
      success: function(e) {
        $('#documents').replaceWith(e);
      }
    });
    return false;
  })
})