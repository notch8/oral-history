$(document).ready(function() {
  $(".spinner").hide();
  // show spinner on AJAX start
  $(document).ajaxStart(function(){
    $(".spinner").show();
  });

  // hide spinner on AJAX stop
  $(document).ajaxStop(function(){
    $(".spinner").hide();
  });
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