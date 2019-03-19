$(document).on('turbolinks:load', function() {
  let searchType = $('#search_field').val()
  $('body').on('change', '#search_field', function(e) {
    searchType = e.target.value;
    let formAction 
    searchType && searchType === "Interview Information" ?  formAction = "/" : formAction = "/full_text";
    $('form.search-query-form').attr("action", formAction);
  })
});