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
  cursorColor: '#ffffff',
  fillParent: true,
  audioRate: 1,
  height: 340,
  barWidth: 2,
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
      current: '--:--:--',
      duration: '--:--:--',
      progressPosition: 0
    }

    this.handleTogglePlay = this.handleTogglePlay.bind(this)
    this.changeVol = this.changeVol.bind(this)
    this.changeSource = changeSource.bind(this)
    this.handleProgressClick = this.handleProgressClick.bind(this)
  }

  render() {
    const { volume, source, playing, sliderPos, currentTime, progressPosition, current, duration } = this.state
    const { image } = this.props

    const width = `${(volume * 100)}%` || '50%'
    const left = sliderPos || '96%'
    const playPause = (playing ? 'pause-button' : 'play-button')

    return (
      <div className="player col-xs-12">
        <div className="col-xs-4">
          <img src={image} className='img-responsive' />
          <a onClick={this.handleTogglePlay} className={playPause}></a>
          <div className="volume-container">
            <span className="fa fa-volume-up">
            </span>
          </div>
          <div
            id="volume-slider"
            className="volume-slider"
            onClick={this.changeVol}
            onMouseDown={this.changeVol}
            onDrag={this.changeVol}
          >
            <div style={{left: left}} className="marker"></div>
            <div style={{width: width}} className="fill"></div>
          </div>
        </div>
        <div className='col-xs-8 wave-box'>
        </div>
        <div id="audioplayer" className='col-xs-8 col-xs-offset-4 progress-container'>
          <div id="timeline"
            onClick={this.handleProgressClick}
            onDragOver={this.handleProgressClick}
          >
            <div 
              id="playhead"
              style={{marginLeft: (isNaN(progressPosition) ? 0 : progressPosition) - 7}}
              draggable
            >
            </div>
          </div>
          <div className="time-container">
            <div>{current}</div>
            <div>{duration}</div>
          </div>
        </div>
        <audio id="audio" ref="audio" src={source} ></audio>
      </div>
    )
  }

  handleProgressClick(e) {
    try {
      const { initialPlay, playing } = this.state
      let { audio } = this.refs
      const { clientX } = e
      let timelineBox = document.getElementById('timeline').getClientRects()[0]
      let position = clientX - timelineBox.left
      let percentage = ( position / timelineBox.width) * audio.duration
      audio.currentTime = percentage

      if (!initialPlay || !playing) {
        audio.play() 
        audio.pause()
      }

      this.setState({progressPosition:  position, initialPlay: true})  
    } catch (error) {
      console.log(error)
    }
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
        let timelineBox = document.getElementById('timeline').getClientRects()[0]
        const progressPosition = (c / d) * timelineBox.width
      
        this.setState({
          currentTime: `00:00:00 / -${formatTime(d-c)}`,
          current: formatTime(c),
          duration: formatTime(d-c),
          progressPosition: progressPosition || 0
        })

        clearInterval(interval)
      }
    }, 200)

    audio.ontimeupdate = () => {
      const c = Math.floor(audio.currentTime)
      const d = Math.floor(audio.duration)
      let timelineBox = document.getElementById('timeline').getClientRects()[0]
      const progressPosition = (c / d) * timelineBox.width

      this.setState({
        currentTime: `${formatTime(c)} / -${formatTime(d-c)}`,
        current: formatTime(c),
        duration: formatTime(d-c),
        progressPosition: progressPosition
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
  if (isNaN(num) || Number.isNaN(num) || num == Infinity) {
    return "00"
  }

  return num > 9 ? `${num}` : `0${num}`
}
