$(document).ready(function() {
  $('body').on('click', '.audio-timestamp-link', function(e) {
    if ( typeof window.CustomEvent === "function" ) return false; //If not IE
    var event = new CustomEvent(
      'jump_to_audio_time',
      {
        bubbles: true,
        cancelable: true,
        detail: {
          jump_to: e.currentTarget.getAttribute('data-start')
        }
      },
    )
    window.dispatchEvent(event)
  })
})
