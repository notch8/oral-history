import React, { Component } from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import Hls from 'hls.js'
import WaveSurfer from 'wavesurfer.js'

const waveOptions = {
  container: '.wave-box',
  backend: 'MediaElement',
  progressColor: '#c2daeb',
  waveColor: '#1e4b87',
  fillParent: true,
  audioRate: 1,
  height: 340,
  barWidth: 2
}

export default class AudioPlayer extends Component {
  constructor(props) {
    super(props)

    const { id, src } = this.props

    this.state = {
      id: id,
      source: src,
      playing: false,
      volume: 1,
    }

    this.handleTogglePlay = this.handleTogglePlay.bind(this)
    this.changeVol = this.changeVol.bind(this)
    this.changeSource = changeSource.bind(this)
  }

  render() {
    const { volume, source, playing, sliderPos } = this.state
    const { image } = this.props

    const width = `${(volume * 100)}%` || '50%'
    const left = sliderPos || '96%'
    const playPause = (playing ? 'pause-button' : 'play-button')

    return (
      <div className="player col-xs-12">
        <audio id="audio" ref="audio" src={source} style={{display: 'none'}}></audio>
        <div className="col-xs-4">
          <img src={image} className='img-responsive' />
          <a onClick={this.handleTogglePlay} className={playPause}></a>
          <div
            id="volume-slider"
            className="volume-slider"
            onClick={this.changeVol}
            onMouseDown={this.changeVol}
            onDrag={this.changeVol}>
            <div style={{left: left}} className="marker"></div>
            <div style={{width: width}} className="fill"></div>
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
    const { source, id } = this.state
    let { audio } = this.refs

    let hls = new Hls()
    hls.loadSource(source)
    hls.attachMedia(audio)

    let wavesurfer = WaveSurfer.create(waveOptions)

    loadPeaks(id, audio, wavesurfer)

    let handler = changeSource(this, hls, wavesurfer, audio, id)

    window.addEventListener('set_audio_player_src', handler)

    this.setState({handler}) // add handler for graceful removal of event listener
  }

  componentWillUnmount() {
    window.removeEventListener('set_audio_player_src', this.state.handler)
  }
}

const changeSource = (component, hls, wavesurfer, audio) => (e) => {
  const { id, src } = e.detail

  hls.detachMedia()
  hls.loadSource(src)
  hls.attachMedia(audio)

  loadPeaks(id, audio, wavesurfer)

  component.setState({
    playing: false,
  })

  audio.oncanplay = () => {
    audio.volume = component.state.volume
    audio.play()

    component.setState({
      playing: true,
    })
  }
}

const loadPeaks = function(id, element, wavesurfer) {
  wavesurfer.util.ajax({
      responseType: 'json',
      url: `/peaks/${id}.json`
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
