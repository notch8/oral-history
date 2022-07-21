class FileCleanup
  def self.purge_files
    directory = Rails.root.join('tmp')
    Dir.glob("#{directory}/*.ffmpeg").map do |ffmpeg|
      if File.mtime(ffmpeg) < Time.now - 4.hours
        File.delete(ffmpeg) 
      end
    end
  end
end