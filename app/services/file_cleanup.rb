class FileCleanup
  def self.purge_files
    Dir.glob("/tmp/ffmpeg-*").map do |ffmpeg|
      if File.mtime(ffmpeg) < (Time.now - 4.hours)
        FileUtils.rm_rf(ffmpeg)
      end
    end
  end
end
