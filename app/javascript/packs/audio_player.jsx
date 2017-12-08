// Run this example by adding <%= javascript_pack_tag 'hello_react' %> to the head of your layout file,
// like app/views/layouts/application.html.erb. All it does is render <div>Hello React</div> at the bottom
// of the page.
//require('wavesurfer.js');
//require('wavesurfer.js/dist/plugin/wavesurfer.timeline.min.js');
//require('wavesurfer.js/dist/plugin/wavesurfer.regions.min.js');
//require('wavesurfer.js/dist/plugin/wavesurfer.minimap.min.js');


import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import Wavesurfer from 'react-wavesurfer';

class AudioPlayer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      audioFile: this.props.url,
      playing: false,
      pos: 0,
      volume: 0.5,
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
      pos: 5
    });
  }

  handleVolumeChange(e) {
    this.setState({
      volume: +e.target.value
    });
  }

  render() {
    const waveOptions = {
      scrollParent: true,
      progressColor: '#ffe800',
      waveColor: '#1e4b87',
      normalize: true,
      barWidth: 1,
      audioRate: 1
    };
    return (
      <div className="player col-xs-12">
        <div className="col-xs-4">
          <a onClick={this.handleTogglePlay} className="play-button">
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

document.addEventListener('DOMContentLoaded', () => {
  ReactDOM.render(
    <AudioPlayer url="/lastdance.mp3" image="/avatar.png" />,
    document.getElementById('player'),
  )
})
