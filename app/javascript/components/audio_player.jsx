import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import Wavesurfer from 'react-wavesurfer';

export default class AudioPlayer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      audioFile: this.props.url,
      playing: false,
      pos: 0,
      volume: 1,
      audioRate: 1
    };
    this.handleTogglePlay = this.handleTogglePlay.bind(this);
    this.handlePosChange = this.handlePosChange.bind(this);
    this.handleReady = this.handleReady.bind(this);
    this.handleVolumeChange = this.handleVolumeChange.bind(this);
    this.handleAudioRateChange = this.handleAudioRateChange.bind(this);
  }

  handleAudioRateChange(e) {
    this.setState({
      audioRate: +e.target.value
    });
  }

  handleTogglePlay() {
    this.setState({
      playing: !this.state.playing
    });
  }

  handlePosChange(e) {
    this.setState({
      pos: e.originalArgs ? e.originalArgs[0] : +e.target.value
    });
  }

  handleReady() {
    this.setState({
      pos: 0
    });
  }

  handleVolumeChange(e) {
    this.setState({
      volume: +e.target.value
    });
  }

  handleNewUrl(e) {
    this.setState({
      audioFile: e.detail.url,
      pos: 0,
      playing: false
    })
    setTimeout(function() {
      this.handleTogglePlay() // TODO is this timeout long enough? is there a better way??
    }.bind(this), 3000)
  }

  componentDidMount() {
    window.addEventListener('newurl', this.handleNewUrl.bind(this))
  }

  componentWillUnmount() {
    window.removeEventListener('newurl', this.handleNewUrl.bind(this))
  }

  render() {
    const waveOptions = {
      scrollParent: true,
      progressColor: '#c2daeb',
      waveColor: '#1e4b87',
      normalize: true,
      audioRate: 1,
      height: 340,
      barWidth: 2,
    };
    var playPause = (this.state.playing ? 'pause-button' : 'play-button')
    return (
      <div className="player col-xs-12">
        <div className="col-xs-4">
          <a onClick={this.handleTogglePlay} className={playPause}>
            <img src={this.props.image} className='img-responsive' />
          </a>
        </div>
        <div className='col-xs-8 wave-box'>
          <Wavesurfer
            volume={this.state.volume}
            pos={this.state.pos}
            options={waveOptions}
            onPosChange={this.handlePosChange}
            audioFile={this.state.audioFile}
            playing={this.state.playing}
            onReady={this.handleReady}
          />
        </div>
      </div>
    );
  }
}
