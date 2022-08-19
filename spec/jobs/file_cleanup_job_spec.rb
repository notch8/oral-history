require 'rails_helper'

describe FileCleanupJob do
  let(:file_cleanup) { FileCleanupJob.new }
  let(:new_folder) { FileUtils.mkdir 'tmp/ffmpeg-1' }
  let(:old_folder) { FileUtils.mkdir 'tmp/ffmpeg-2' }

  after(:each) do
    FileUtils.rm_rf(new_folder)
  end

  it "purges ffmpeg files that are over 4 hours old" do
    FileUtils.touch old_folder, :mtime => Time.now - 5.hours
    directory = Rails.root.join('tmp')
    count_of_folders_in_temp =  Dir.glob("#{directory}/*").count
    file_cleanup.cleanup(directory)
    expect(Dir.glob("#{directory}/*").count).to eq count_of_folders_in_temp - 1
  end


  it "doesn't delete files that are less than 4 hours old" do
    directory = Rails.root.join('tmp')
    count_of_folders_in_temp = Dir.glob("#{directory}/*").count
    file_cleanup.cleanup(directory)
    expect(Dir.glob("#{directory}/*").count).to eq count_of_folders_in_temp
  end
end
