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

    const { id, src, peaks, transcript } = this.props

    this.state = {
      id: id,
      source: src,
      peaks: peaks,
      transcript: transcript,
      playing: false,
      initialPlay: false,
      volume: 1,
      currentTime: '--:--:-- / --:--:--',
      scrollTimeIndex: 0,
    }

    this.handleTogglePlay = this.handleTogglePlay.bind(this)
    this.changeVol = this.changeVol.bind(this)
    this.changeSource = changeSource.bind(this)
  }

  render() {
    const { volume, source, playing, sliderPos, currentTime, mapped } = this.state
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
    let { playing, initialPlay } = this.state
    let { audio } = this.refs
    const { id, src, peaks, transcript } = this.props

    playing = !playing

    if (playing) {
      audio.play()
    } else {
      audio.pause()
    }

    if (playing && !initialPlay) {
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

    this.setState({ playing, initialPlay: true })
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
      let { scrollTimeIndex } = this.state
      const c = Math.floor(audio.currentTime)
      const d = Math.floor(audio.duration)

      let mapped = {}

      // NOTE (george): yes, this isn't ideal and queries the DOM every iteration
      // but because the render methods between the file_view and the audio_player aren't
      // synced it is simpler to constantly check the DOM. 
      // Ideally, we would make this entire page (or at least the player, transcript, and sections)
      // React-ified and use something like React Provider (instead of Redux) to manage the state.
      let timestamps = Array.from(document.getElementsByClassName('audio-timestamp-link'))
      timestamps.map(function (link) { mapped[timeStrToSeconds(link.getAttribute('data-start'))] = link })

      let scrollTimes = Object.keys(mapped)
      
      let nextScrollTime = scrollTimes[scrollTimeIndex]
      
      if (mapped[c] != undefined && nextScrollTime <= c) {
        mapped[nextScrollTime].scrollIntoView({
          behavior: "smooth",
          block: "start",
          inline: "nearest",
        })
        scrollTimeIndex += 1
      }

      this.setState({
        currentTime: `${formatTime(c)} / -${formatTime(d-c)}`,
        scrollTimeIndex,
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
  const { mapped } = component.state

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
      playing: true
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
  const seconds = timeStrToSeconds(e.detail.jump_to)

  audio.currentTime = seconds
}

const timeStrToSeconds = (str) => {
  let parts = str.split(':').reverse()

  const seconds = parts.reduce((acc, val, i) => {
    return acc + (parseInt(val) * (i > 0 ? 60 ** i : 1))
  }, 0)

  return seconds
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
  if (isNaN(num) || Number.isNaN(num) || num == Infinity) {
    return "00"
  }

  return num > 9 ? `${num}` : `0${num}`
}
