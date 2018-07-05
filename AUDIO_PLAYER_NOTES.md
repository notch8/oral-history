# Audio Notes
- \*.m3u8 is a playlist file format in use by HLS (Apple - HTTP Live Streaming)
- Essentially, under HLS \*.m3u8 files concatenate MP3, AAC, AAC-\* files and are interpreted by the browser as a single audio stream.

## Useful Links
- https://github.com/collab-project/videojs-wavesurfer#using-the-plugin
- https://github.com/videojs/videojs-contrib-hls
- https://github.com/collab-project/videojs-wavesurfer/issues/17
- https://github.com/collab-project/videojs-wavesurfer
- https://github.com/katspaugh/wavesurfer.js/issues/1078
- https://en.wikipedia.org/wiki/M3U
- https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/StreamingMediaGuide/HTTPStreamingArchitecture/HTTPStreamingArchitecture.html
- https://www.wowza.com/community/questions/2529/how-to-get-proper-m3u8-url-for-live-rtsp-stream.html

## Response Headers
```Summary
URL: https://wowza.library.ucla.edu/dlp/definst/mp3:oralhistory/21198-zz000s4rf0-1-submaster.mp3/playlist.m3u8
Status: 200 OK
Source: Network
Address: 164.67.40.233:443

Request
GET /dlp/definst/mp3:oralhistory/21198-zz000s4rf0-1-submaster.mp3/playlist.m3u8 HTTP/1.1
Origin: http://localhost:8000
Host: wowza.library.ucla.edu
Accept: */*
Connection: keep-alive
Accept-Language: en-us
Accept-Encoding: br, gzip, deflate
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1.1 Safari/605.1.15
Referer: http://localhost:8000/catalog/8

Response
HTTP/1.1 200 OK
Content-Type: application/vnd.apple.mpegurl
Access-Control-Allow-Credentials: true
Date: Mon, 11 Jun 2018 17:59:36 GMT
Cache-Control: no-cache
Access-Control-Allow-Methods: OPTIONS, GET, POST, HEAD
Server: WowzaStreamingEngine/4.7.1
Access-Control-Expose-Headers: Date, Server, Content-Type, Content-Length
Content-Length: 106
Accept-Ranges: bytes
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: Content-Type, User-Agent, If-Modified-Since, Cache-Control, Range```
