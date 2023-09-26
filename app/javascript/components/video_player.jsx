import React, { Component } from 'react'
import Clappr from 'clappr'
import PlaybackRatePlugin from 'clappr-playback-rate-plugin'
import { FastForward, SkipBackward } from './skip_plugins'

export default class VideoPlayer extends Component{
  constructor(props) {
    super(props)
    this.state = { player: null }
  }

  componentDidUpdate(prevProps) {
    const { source, image } = this.props
    const { player } = this.state

    if (player) {
      // NOTE(dewey4iv @ 2020/10/12): this was commented out when we found it
      //player.destroy()
    }

    if (source != prevProps.source || (!player && source)) {
      const player = new Clappr.Player({
        source: source,
        src: source,
        poster: image,
        plugins: [
          Clappr.FlasHLS,
          PlaybackRatePlugin,
          SkipBackward,
          FastForward,
          ],
        width: 800,
        baseUrl: '/assets/clappr',
        parent: this.refs.player,
        hlsjsConfig: { enableWorker: true }
      })

      this.setState({ player: player })
    }
  }

  componentWillUnmount() {
    this.destroyPlayer()
  }

  destroyPlayer() {
    const { player } = this.state
    if (player) {
      player.destroy()
    }
    this.setState({ player: null })
  }

  render() {
    return (
      <div id="player" ref="player"></div>
    )
  }
}
