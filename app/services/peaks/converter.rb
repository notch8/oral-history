module Peaks
  class Converter
    DEFAULT_FFMPEG_CALL = "ffmpeg -loglevel panic -i %s -acodec pcm_s16le -ar 44100 %s"

    def initialize(tmp_path = nil)
      @tmp_path = tmp_path || 'ffmpeg-'
    end

    def fetch(remote_file)
      convert remote_file, @tmp_path
    end

    def convert(src, dst)
      dir = Dir.mktmpdir(@tmp_path, nil)
      dst_file = Pathname.new(dir).join('audio.wav').cleanpath.to_s

      cmd = sprintf(DEFAULT_FFMPEG_CALL, src, dst_file)

      pid = spawn(cmd)
      Process.wait pid

      return dst_file
    end
  end
end
