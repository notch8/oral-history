$(document).ready(function() {
  $(".spinner").hide();
  
  $(document).ajaxStart(function(){
    $(".spinner").show();
  });

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