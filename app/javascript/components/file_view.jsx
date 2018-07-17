import React, { Component } from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
var xslt = require('xslt')

export default class FileView extends Component {
  
  constructor(props) {
    super(props)
    this.state = {
      timelog: '',
    }
  }

  render() {
    return(
      <div dangerouslySetInnerHTML={{ __html: this.state.timelog}} /> 
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
    let timelog = e.detail.timelog
    var apiRequest1 = fetch('/master.xml').then(function(response){
      return response.text()
    });
    var apiRequest2 = fetch('/tei.xslt').then(function(response){
      return response.text()
    });
    
    Promise.all([apiRequest1,apiRequest2]).then((values) => {
      let outputXmlString = xslt(values[0], values[1]);
      this.setState({ timelog: outputXmlString })
    })
  }
}
