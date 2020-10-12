import React, { Component } from 'react'
import Hls from 'hls.js'
import WaveSurfer from 'wavesurfer.js'
import VideoPlayer from './video_player'

const waveOptions = {
  container: '.wave-box',
  backend: 'MediaElement',
  progressColor: '#c2daeb',
  waveColor: '#1e4b87',
  cursorColor: '#ffffff',
  fillParent: true,
  audioRate: 1,
  height: 285,
  barWidth: 2
}

export default class MediaPlayer extends Component {
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
      current: '--:--:--',
      duration: '--:--:--',
      progressPosition: 0,
      isSrolling: false,
      currentScrolledTime: 0,
    }
  }

  render() {
    const { typeOfResource } = this.props
    switch (typeOfResource) {
      case "moving image":
        return this.renderVideo();
      default:
        return this.renderAudio();
    }
  }

  renderVideo = () => {
    const { image } = this.props
    const { source } = this.state
    return(
      <div className="row player">
        <VideoPlayer
          source={source}
          image={image}
        />
        <audio
          id="audio"
          ref="audio"
          style={{display: 'none'}}
        ></audio>
      </div>
    )
  }

  renderAudio = () => {
    const { volume, source, playing, progressPosition, current, duration, isScrolling } = this.state
    const { image } = this.props
    const playPause = (playing ? 'pause-button' : 'play-button')

    return (
      <div className="row player">
        <audio id="audio" ref="audio" src={source} style={{display: 'none'}}></audio>
        <div className="col-sm-3 narrator-image-container" style={{backgroundImage: `url(${image})`, backgroundPosition: "center center", backgroundSize: "contain", backgroundRepeat: "no-repeat"}}>
          <a onClick={this.handleTogglePlay} className={playPause}></a>
          <div className="volume-container">
            <span className="fa fa-volume-up">
            </span>
            <input
              id="volume-slider"
              ref="volume"
              type="range"
              min="0"
              max="1"
              value={volume}
              step="0.01"
              onChange={this.changeVol}
            />
            <select onChange={this.handleSpeedChange}>
              <option value="0.5">0.5</option>
              <option value="1.0" selected>1.0</option>
              <option value="1.5">1.5</option>
              <option value="2.0">2.0</option>
            </select>


          </div>
        </div>

        <div className='col-sm-9 wave-box'></div>
        <div id="audioplayer" className='col-sm-9 col-sm-offset-3 progress-container'>
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
        <div className='col-sm-3 autoscroll-button'>
          <button
            onClick={this.handleToggleIsScrolling}
            className="btn btn-xs u-btn-outline-primary"
          >
            { isScrolling ? (
              <i className="fa fa fa-check g-font-size-18"></i>
            ) : (
              <i className="fa fa-close g-font-size-18"></i>
            )}
            &nbsp;Autoscroll
          </button>
        </div>
      </div>
    )
  }

  handleSpeedChange = (e) => {
    const { audio } = this.refs
    audio.playbackRate = e.target.value
  }

  handleProgressClick = (e) => {
    try {
      const { initialPlay, playing } = this.state
      const { audio } = this.refs
      const { clientX } = e
      const timelineBox = document.getElementById('timeline').getClientRects()[0]
      const position = clientX - timelineBox.left
      const percentage = ( position / timelineBox.width) * audio.duration
      audio.currentTime = percentage

      if (!initialPlay || !playing) {
        audio.play()
        audio.pause()
      }

      this.setState({ progressPosition:  position, initialPlay: true })
    } catch (error) {
      console.log(error)
    }
  }

  changeVol = (e) => {
    const { audio, volume } = this.refs
    audio.volume = volume.value

    this.setState({
      volume: volume.value,
    })
  }

  handleTogglePlay = () => {
    const { playing, initialPlay } = this.state
    const { audio } = this.refs
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

  handleToggleIsScrolling = () => {
    const { isScrolling } = this.state

    this.setState({ isScrolling: !isScrolling })
  }

  componentDidMount() {
    let wavesurfer
    const { id, source, peaks } = this.state
    const { typeOfResource } = this.props
    const { audio } = this.refs
    if (typeOfResource === "audio") {
      const interval = setInterval(() => {
        if (audio.duration > 0) {
          const c = Math.floor(audio.currentTime)
          const d = Math.floor(audio.duration)
          const timelineBox = document.getElementById('timeline').getClientRects()[0]
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
    }

    audio.ontimeupdate = () => {
      const { currentScrolledTime, isScrolling } = this.state
      const c = Math.floor(audio.currentTime)
      const d = Math.floor(audio.duration)
      const timelineBox = document.getElementById('timeline').getClientRects()[0]
      const progressPosition = (c / d) * timelineBox.width

      // NOTE (george): yes, this isn't ideal and queries the DOM every iteration
      // but because the render methods between the file_view and the audio_player aren't
      // synced it is simpler to constantly check the DOM.
      // Ideally, we would make this entire page (or at least the player, transcript, and sections)
      // React-ified and use something like React Provider (instead of Redux) to manage the state.
      let mapped = {}
      const timestamps = Array.from(document.getElementsByClassName('audio-timestamp-link'))
      timestamps.map(function (link) { mapped[timeStrToSeconds(link.getAttribute('data-start'))] = link })

      const nextScrollTime = getNearestTimeIndex(Object.keys(mapped), c)

      if (isScrolling && nextScrollTime != currentScrolledTime) {
        mapped[nextScrollTime].scrollIntoView({
          behavior: "smooth",
          block: "center",
          inline: "nearest",
        })
      }

      this.setState({
        currentTime: `${formatTime(c)} / -${formatTime(d-c)}`,
        currentScrolledTime: nextScrollTime,
        current: formatTime(c),
        duration: formatTime(d-c),
        progressPosition: progressPosition
      })
    }

    let hls = new Hls()
    hls.loadSource(source)
    hls.attachMedia(audio)

    if (typeOfResource === "audio") {
      wavesurfer = WaveSurfer.create(waveOptions)
      wavesurfer.load(audio, peaks);
    }

    let sourceHandler = changeSource(this, hls, wavesurfer, audio, id, typeOfResource)
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

const changeSource = (component, hls, wavesurfer, audio, typeOfResource) => (e) => {
  const { src, peaks } = e.detail
  const { mapped } = component.state

  hls.detachMedia()
  hls.loadSource(src)
  hls.attachMedia(audio)

  let wavesurfer
  if (typeOfResource === "audio") {
    wavesurfer.load(audio, peaks);
  }

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

const jumpTo = (audio) => (e) => {
  const seconds = timeStrToSeconds(e.detail.jump_to)

  audio.currentTime = seconds
}

const timeStrToSeconds = (str) => {
  const parts = str.split(':').reverse()

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

const getNearestTimeIndex = (haystack, needle) => {
  const nearest = haystack[0]

  for (let i = 0; i < haystack.length; i++) {
    if (nearest <= needle) {
      nearest = haystack[i]
    }

    if (haystack[i+1] > needle) {
      return nearest
    }
  }

  return nearest
}
