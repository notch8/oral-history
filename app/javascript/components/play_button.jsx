import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'

export default class PlayButton extends React.Component {
  handleOnClick(e){
    var newUrl = this.props.url;
    var event = new CustomEvent('newurl',
                                { bubbles: true,
                                  cancelable: true,
                                  detail: { url: newUrl}
                                });
    window.dispatchEvent(event);
  }

  render(){
    return(
      <div className="player">
        <a className="play-icon" onClick={this.handleOnClick.bind(this)}>
          <i className="fa fa-play-circle-o g-font-size-18"></i>
        </a>
      </div>
    )
  }

}
