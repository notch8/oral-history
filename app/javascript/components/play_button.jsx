import React, { Component } from 'react'

export default class PlayButton extends Component {
  render() {
    return (
      <div className="player">
        <a className="play-icon" onClick={this.handleOnClick.bind(this)}>
          <i className="fa fa-play-circle-o g-font-size-18"></i>
        </a>
      </div>
    )
  }

  handleOnClick(e) {
    const { id, src, peaks, transcript } = this.props

    window.scrollTo({
      top: 0,
      behavior: "smooth"
    })

    var event = new CustomEvent(
      'set_audio_player_src',
      {
        bubbles: true,
        cancelable: true,
        detail: { id, src, peaks, transcript }
      },
    )

    window.dispatchEvent(event)
  }
}
