import React, { Component } from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import Hls from 'hls.js'

const waveOptions = {
  container: '.wave-box',
  backend: 'MediaElement',
  progressColor: '#c2daeb',
  waveColor: '#1e4b87',
  audioRate: 1,
  height: 340,
  barWidth: 2
}

export default class AudioPlayer extends Component {
  constructor(props) {
    super(props)

    const { url } = this.props

    this.state = {
      source: url,
      playing: false,
      volume: 1,
    }

    this.handleTogglePlay = this.handleTogglePlay.bind(this)
    this.changeVol = this.changeVol.bind(this)
  }

  render() {
    const { volume, source, playing, sliderPos } = this.state

    var playPause = (playing ? 'pause-button' : 'play-button')

    return (
      <div className="player col-xs-12">
        <audio id="audio" ref="audio" volume={volume} src={source} style={{display: 'none'}}></audio>
        <div className="col-xs-4">
          <img src={this.props.image} className='img-responsive' />
          <a onClick={this.handleTogglePlay} className={playPause}></a>
          <div id="volume-slider" className="volume-slider" onClick={this.changeVol} onDrag={this.changeVol}>
            <div style={{left: sliderPos || '96%'}} className="marker"></div>
            <div style={{width: `${(volume * 100)}%` || '50%'}} className="fill"></div>
          </div>
        </div>
        <div className='col-xs-8 wave-box'>
        </div>
      </div>
    )
  }

  changeVol(e) {
    let b = document.getElementById('volume-slider').getClientRects()[0]
    let { audio } = this.refs

    const volume = computeVolume(e, b)

    audio.volume = volume

    this.setState({
      volume,
      sliderPos: e.clientX - b.left - 8, // some math to center the mark on the pointer
    })
  }

  handleTogglePlay() {
    let { playing } = this.state
    let { audio } = this.refs

    playing = !playing

    this.setState({ playing })

    if (playing) {
      audio.play()
    } else {
      audio.pause()
    }
  }

  componentDidMount() {
    const { source } = this.state
    let { audio } = this.refs

    let hls = new Hls()
    hls.loadSource(source)
    hls.attachMedia(audio)

    let wavesurfer = window.WaveSurfer.create(waveOptions)

    loadPeaks(audio, wavesurfer)

    window.addEventListener('set_audio_player_src', (e) => {
      hls.detachMedia()
      hls.loadSource(e.detail.url)
      hls.attachMedia(audio)

      loadPeaks(audio, wavesurfer)

      this.setState({
        playing: false,
      })

      audio.oncanplay = () => {
        audio.volume = this.state.volume
        audio.play()

        this.setState({
          playing: true,
        })
      }
    })
  }

  componentWillUnmount() {
    window.removeEventListener('set_audio_player_src', this.handleNewSrc.bind(this))
  }
}

const loadPeaks = function(element, wavesurfer) {
  wavesurfer.util.ajax({
      responseType: 'json',
      url: '/peaks.json'
  })
  .on('success', function(data) {
    wavesurfer.load(element, data);
  })
}

const computeVolume = (e, b) => {
  let volume = ((e.clientX - b.left) / b.width)

  if (volume < 0) {
    volume = 0
  }

  if (volume > 1) {
    volume = 1
  }

  return volume
}
