import React, { Component } from 'react'
import ReactHLS from 'react-hls-player'
import Clappr from 'clappr'
import PlaybackRatePlugin from 'clappr-playback-rate-plugin'

export default class VideoPlayer extends Component{
  constructor(props){
    super(props)
    this.state = {player: null}
  }

  componentDidUpdate(prevProps){
    const{ source, image} = this.props
    const{ player } = this.state
    if(player){
      //player.destroy()
    }
    if(source != prevProps.source || (!player && source)){
      const player = new Clappr.Player({
	source: source,
        poster: image,
        plugins: [Clappr.FlasHLS, PlaybackRatePlugin],
        width: 800,
        baseUrl: "/assets/clappr",
        parent: this.refs.player,
	hlsjsConfig: {
	  enableWorker: true
	}
      });

      this.setState({player: player})
      console.log("HELLOOOOOOOO", player)
    }
  }

  componentWillUnmount() {
    this.destroyPlayer();
  }
  
  destroyPlayer() {
    const{ player } = this.state
    if (player) {
      player.destroy();
    }
    this.setState({player: null})
  }

  render(){
    return (
      <div ref="player"></div>
    )
  }
}
