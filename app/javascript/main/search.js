$(document).on('turbo:load', function() {
  console.log("hello search.js loaded");
  let searchType = $('#search_field').val()
  let formAction 
  searchType && searchType === "Interview Information" ?  formAction = "/" : formAction = "/full_text";
  $('form.search-query-form').attr("action", formAction);
  $('body').on('change', '#search_field', function(e) {
    searchType = e.target.value;
    let formAction 
    searchType && searchType === "Interview Information" ?  formAction = "/" : formAction = "/full_text";
    $('form.search-query-form').attr("action", formAction);
  })
});