class FileCleanupJob < ApplicationJob
  repeat 'every 12 hours'

  def perform
    cleanup("/tmp")
    cleanup(Rails.root.join('tmp'))
  end

  def cleanup(directory)
    Dir.glob("#{directory}/ffmpeg-*").map do |ffmpeg|
      if File.mtime(ffmpeg) < (Time.now - 4.hours)
        FileUtils.rm_rf(ffmpeg)
      end
    end
  end
end
