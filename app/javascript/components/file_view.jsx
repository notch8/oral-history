import React, { Component } from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'

export default class FileView extends Component {
  
  constructor(props) {
    super(props)
    this.state = {
      file: '',
    }
  }

  render() {
    return(
      <div>
        {this.state.file}
      </div>
    )
  }
    
  componentDidMount() {
    let handler = this.changeFile.bind(this)
    window.addEventListener('set_audio_player_src', handler)
  
    this.setState({handler}) // add handler for graceful removal of event listener
  }
  
  componentWillUnmount() {
    window.removeEventListener('set_audio_player_src', this.state.handler)
  }

  changeFile(e) {
    this.setState({file: e.detail.file})
  }
}

