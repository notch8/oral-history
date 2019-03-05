$(document).ready(function() {
  $('body').on('change', '#search_field', function(e) {
    let searchType = e.target.value;
    let formAction 
    searchType && searchType === "Interview Information" ?  formAction = "/" : formAction = "/full_text";
    $('form.search-query-form').attr("action", formAction);
  })
})