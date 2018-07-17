import React, { Component } from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
var xslt = require('xslt')

export default class FileView extends Component {
  
  constructor(props) {
    super(props)
    this.state = {
      timelog: '',
      transcriptShow: false,
      isLoading: false,
      error: null,
    }
  }

  render() {
    return(
      <div>
        { this.state.error &&
          <div className="container transcript-container-loading text-danger g-brd-around g-brd-red rounded-0">{ this.state.error.message }</div>
        }
        { this.state.isLoading && 
          <div className="container g-brd-primary g-brd-around rounded-0 transcript-container-loading">Transcripts are loading...</div>
        }
        { this.state.transcriptShow ? (
          <div className="container g-brd-primary g-brd-around rounded-0 transcript-container" dangerouslySetInnerHTML={{ __html: this.state.timelog}} /> 
          ) : (
          <div></div>
          ) 
        }
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
    this.setState({isLoading: true})
    var error
    let timelog = e.detail.timelog
    var apiRequest1 = fetch('/master.xml').then(function(response){
      if(response.ok) {
        return response.text()
      } else {
        throw new Error('Sorry, something went wrong while loading transcript.')
      }
    });
    var apiRequest2 = fetch('/tei.xslt').then(function(response){
      if (response.ok) {
        return response.text()
      } else {
        throw new Error('Sorry, something when wrong when processing the transcript')
      }
    });
    
    Promise.all([apiRequest1,apiRequest2]).then((values) => {
      let outputXmlString = xslt(values[0], values[1])
      this.setState({ timelog: outputXmlString, transcriptShow: true, isLoading: false })
    }).catch(error => this.setState({ error, isLoading: false }))
  }
}
