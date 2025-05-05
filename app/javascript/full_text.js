document.addEventListener("turbo:load", function () {
  console.log("✅ full_text.js loaded");

  $(".spinner").hide();

  $(document).ajaxStart(function () {
    $(".spinner").show();
  });

  $(document).ajaxStop(function () {
    $(".spinner").hide();
  });

  $('body').on('click', '.load-more', function (e) {
    e.preventDefault();
    $.ajax({
      url: this.href + "&partial=true",
      success: function (response) {
        $('#documents').replaceWith(response);
      },
      error: function () {
        alert('request failed');
      }
    });
  });
});
