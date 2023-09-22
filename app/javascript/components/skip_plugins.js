import Clappr from 'clappr';

class FastForward extends Clappr.UICorePlugin {
  get name() { return 'fast_forward' }
  get attributes() { return { class: 'fast-forward', id: 'fast-forward' } }

  get events() {
    const events = { click: 'onClick' }
    return events
  }

  constructor(core) {
    super(core)
    this.bindEvents()
  }

  bindEvents() {
    this.stopListening(this.core)
    this.listenTo(this.core, Clappr.Events.CORE_ACTIVE_CONTAINER_CHANGED, this.onContainerChanged)
    this.listenTo(this.core, Clappr.Events.CORE_READY, this.bindMediaControlEvents)
  }

  bindMediaControlEvents() {
    this.stopListening(this.core.mediaControl)
    this.listenTo(this.core.mediaControl, Clappr.Events.MEDIACONTROL_RENDERED, this.render)
  }

  onContainerChanged() {
    this.container && this.stopListening(this.container)
    this.container = this.core.activeContainer
  }

  onClick() {
    this.core.getCurrentPlayback().seek(this.core.getCurrentPlayback().getCurrentTime() + 5)
  }

  show() {
    this.$el.show()
  }

  hide() {
    this.$el.hide()
  }

  render() {
    // Create the SVG element
    const skipForwardSvg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    skipForwardSvg.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
    skipForwardSvg.setAttribute('width', '20');
    skipForwardSvg.setAttribute('height', '20');
    skipForwardSvg.setAttribute('fill', 'rgb(102, 178, 255)');
    skipForwardSvg.setAttribute('viewBox', '0 0 16 16');
    skipForwardSvg.setAttribute('aria-hidden', 'true');
    skipForwardSvg.setAttribute('aria-label', 'Fast Forward 10 seconds');
    skipForwardSvg.setAttribute('type', 'button');
    skipForwardSvg.setAttribute('fill-opacity', '.5');

    // Create the path element and set its attributes
    const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
    path.setAttribute('d', 'M15.5 3.5a.5.5 0 0 1 .5.5v8a.5.5 0 0 1-1 0V8.753l-6.267 3.636c-.54.313-1.233-.066-1.233-.697v-2.94l-6.267 3.636C.693 12.703 0 12.324 0 11.693V4.308c0-.63.693-1.01 1.233-.696L7.5 7.248v-2.94c0-.63.693-1.01 1.233-.696L15 7.248V4a.5.5 0 0 1 .5-.5z');

    // Append the path element to the SVG element
    skipForwardSvg.appendChild(path);
    console.log(skipForwardSvg)
    this.$el.append(Clappr.Styler.getStyleFor('.fast-forward { position: absolute; top: 5px; left: 120%; height: 20px; width: 20px; z-index: 999;}'))
    this.core.mediaControl && this.core.mediaControl.$('.media-control-left-panel').append(this.el)
    const skipForwardDiv = document.getElementById("fast-forward")
    skipForwardDiv && skipForwardDiv.appendChild(skipForwardSvg)
    return this
  }
}

class SkipBackward extends Clappr.UICorePlugin {
  get name() { return 'skip_backward' }
  get attributes() { return { class: 'skip-backward', id: 'skip-backward' } }

  get events() {
    const events = { click: 'onClick' }
    return events
  }

  constructor(core) {
    super(core)
    this.bindEvents()
  }

  bindEvents() {
    this.stopListening(this.core)
    this.listenTo(this.core, Clappr.Events.CORE_ACTIVE_CONTAINER_CHANGED, this.onContainerChanged)
    this.listenTo(this.core, Clappr.Events.CORE_READY, this.bindMediaControlEvents)
  }

  bindMediaControlEvents() {
    this.stopListening(this.core.mediaControl)
    this.listenTo(this.core.mediaControl, Clappr.Events.MEDIACONTROL_RENDERED, this.render)
  }

  onContainerChanged() {
    this.container && this.stopListening(this.container)
    this.container = this.core.activeContainer
  }

  onClick() {
    if (this.core.getCurrentPlayback().getCurrentTime() > 5) {
      this.core.getCurrentPlayback().seek(this.core.getCurrentPlayback().getCurrentTime() - 5)
    } else {
      this.core.getCurrentPlayback().seek(0)
    }
  }

  show() {
    this.$el.show()
  }

  hide() {
    this.$el.hide()
  }

  render() {
     // Create the SVG element
    const skipBackwardSvg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    skipBackwardSvg.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
    skipBackwardSvg.setAttribute('width', '20');
    skipBackwardSvg.setAttribute('height', '20');
    skipBackwardSvg.setAttribute('fill', 'rgb(102, 178, 255)');
    skipBackwardSvg.setAttribute('viewBox', '0 0 16 16');
    skipBackwardSvg.setAttribute('aria-hidden', 'true');
    skipBackwardSvg.setAttribute('aria-label', 'Rewind 10 seconds');
    skipBackwardSvg.setAttribute('type', 'button');
    skipBackwardSvg.setAttribute('fill-opacity', '.5');

    // Create the path element and set its attributes
    const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
    path.setAttribute('d', 'M.5 3.5A.5.5 0 0 0 0 4v8a.5.5 0 0 0 1 0V8.753l6.267 3.636c.54.313 1.233-.066 1.233-.697v-2.94l6.267 3.636c.54.314 1.233-.065 1.233-.696V4.308c0-.63-.693-1.01-1.233-.696L8.5 7.248v-2.94c0-.63-.692-1.01-1.233-.696L1 7.248V4a.5.5 0 0 0-.5-.5');

    // Append the path element to the SVG element
    skipBackwardSvg.appendChild(path);
    console.log(skipBackwardSvg)
    this.$el.append(Clappr.Styler.getStyleFor('.skip-backward { position: absolute; top: 5px; left: 100%; height: 20px; width: 20px; z-index: 999;}'))
    this.core.mediaControl && this.core.mediaControl.$('.media-control-left-panel').append(this.el)
    const skipBackwardDiv = document.getElementById("skip-backward")
    skipBackwardDiv && skipBackwardDiv.appendChild(skipBackwardSvg)
    return this
  }
}

export { FastForward, SkipBackward };