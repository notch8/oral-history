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
      <div className="player col-xs-4">
        <div className="col-xs-4">
          <a onClick={this.handleOnClick.bind(this)}>
            <img src={this.props.image} className='img-responsive' />
            PLAY
          </a>
        </div>
      </div>
    )
  }

}
