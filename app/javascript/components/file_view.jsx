import React, { Component } from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'

export default class FileView extends Component {
  constructor(props) {
    super(props)

    const { transcript } = props

    this.state = {
      error: null,
      isPlaying: false,
      transcript,
    }
  }

  render() {
    const { error, isPlaying, transcript } = this.state

    return (
      <div>
        {error &&
          <div className="container transcript-container-loading text-danger g-brd-around g-brd-red rounded-0">{error.message}</div>
        }

        {transcript && isPlaying ? (
          <div><div ref='container' className="container g-brd-primary g-brd-around rounded-0 transcript-container" dangerouslySetInnerHTML={{ __html: transcript}} />
          <div className="text-right drag-helper"><small className="form-text text-right">(pull down to resize)</small></div>
          </div>
        ) : (
          <div></div>
        )}
      </div>
    )
  }

  componentDidMount() {
    let handler = this.respondToPlay.bind(this)

    window.addEventListener('set_audio_player_src', handler)

    this.setState({handler}) // add handler for graceful removal of event listener
  }

  componentWillUnmount() {
    window.removeEventListener('set_audio_player_src', this.state.handler)
  }

  respondToPlay(e) {
    this.setState({
      isPlaying: true,
      transcript: e.detail.transcript
    })

    if (this.refs.container) {
      this.refs.container.scrollTop = 0
    }
  }
}
