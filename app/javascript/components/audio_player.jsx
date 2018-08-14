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

    const { id, src, peaks } = this.props

    this.state = {
      id: id,
      source: src,
      peaks: peaks,
      playing: false,
      volume: 1,
      currentTime: '--:--:-- / --:--:--',
    }

    this.handleTogglePlay = this.handleTogglePlay.bind(this)
    this.changeVol = this.changeVol.bind(this)
    this.changeSource = changeSource.bind(this)
  }

  render() {
    const { volume, source, playing, sliderPos, currentTime } = this.state
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
          <div className="time-box">{currentTime}</div>
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
    const { id, source, peaks } = this.state
    let { audio } = this.refs

    const interval = setInterval(() => {
      if(audio.duration > 0) {
        const c = Math.floor(audio.currentTime)
        const d = Math.floor(audio.duration)

        this.setState({
          currentTime: `00:00:00 / -${formatTime(d-c)}`
        })

        clearInterval(interval)
      }
    }, 200)

    audio.ontimeupdate = () => {
      const c = Math.floor(audio.currentTime)
      const d = Math.floor(audio.duration)

      this.setState({
        currentTime: `${formatTime(c)} / -${formatTime(d-c)}`
      })
    }

    let hls = new Hls()
    hls.loadSource(source)
    hls.attachMedia(audio)

    let wavesurfer = WaveSurfer.create(waveOptions)

    wavesurfer.load(audio, peaks);

    let sourceHandler = changeSource(this, hls, wavesurfer, audio, id)
    window.addEventListener('set_audio_player_src', sourceHandler)

    let jumpHandler = jumpTo(audio)
    window.addEventListener('jump_to_audio_time', jumpHandler)

    this.setState({
      sourceHandler,
      jumpHandler,
    }) // add sourceHandler and jumpHandler for graceful removal of event listeners
  }

  componentWillUnmount() {
    const { sourceHandler, jumpHandler } = this.state

    window.removeEventListener('set_audio_player_src', sourceHandler)
    window.removeEventListener('jump_to_audio_time', jumpHandler)
  }
}

const changeSource = (component, hls, wavesurfer, audio) => (e) => {
  const { id, src, peaks } = e.detail

  hls.detachMedia()
  hls.loadSource(src)
  hls.attachMedia(audio)

  wavesurfer.load(audio, peaks);

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

const jumpTo = (audio) => (e) => {
  let parts = e.detail.jump_to.split(':').reverse()

  let seconds = parts.reduce((acc, val, i) => {
    return acc + (parseInt(val) * (i > 0 ? 60 ** i : 1))
  }, 0)

  audio.currentTime = seconds
}

const formatTime = (seconds) => {
  if (seconds == 0) {
    return '00:00:00'
  }

  const hours = Math.floor(seconds / 3600)
  const mins = Math.floor(seconds / 60 % 60)
  const secs = Math.floor(seconds % 60)

  return `${pad(hours)}:${pad(mins)}:${pad(secs)}`
}

const pad = (num) => {
  if (num == NaN) {
    return "00"
  }

  return num > 9 ? `${num}` : `0${num}`
}
