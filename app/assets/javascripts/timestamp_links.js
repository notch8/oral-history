$(document).ready(function() {
  $('body').on('click', '.audio-timestamp-link', function(e) {
    CustomEvent = window.CustomEvent;

    if (typeof CustomEvent !== 'function') {
      CustomEvent = function(event, params) {
        var evt;
        evt = document.createEvent('CustomEvent');
        evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
        return evt;
      };
      CustomEvent.prototype = window.Event.prototype;
    }
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
