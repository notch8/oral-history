module Peaks
  class Converter
    def initialize(tmp_path = nil)
      @tmp_path = tmp_path || 'ffmpeg-'
    end

    def fetch(remote_file)
      convert remote_file, @tmp_path
    end

    def convert(src, dst)
      dir = Dir.mktmpdir(@tmp_path, nil)
      dst_file = "#{dir}/audio.wav"

      cmd = "ffmpeg -i #{src} -acodec pcm_s16le -ar 44100 #{dst_file}"

      puts "Running: \n #{cmd}"

      pid = spawn(cmd)

      Process.wait pid

      return dst_file
    end
  end
end
