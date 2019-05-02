$(document).ready(function() {
  if (navigator.appName == 'Microsoft Internet Explorer' ||  !!(navigator.userAgent.match(/Trident/) || navigator.userAgent.match(/rv:11/)) || (typeof $.browser !== "undefined" && $.browser.msie == 1)) {
    // Display IE warning message
    $('.show-for-ie').css("display","block")
  }
}); 