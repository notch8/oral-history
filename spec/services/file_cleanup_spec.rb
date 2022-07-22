require 'rails_helper'

describe FileCleanup do
  let(:new_file) { Tempfile.create(['tmp_1', '.ffmpeg'], 'tmp') }
  let(:old_file) { Tempfile.create(['tmp_1', '.ffmpeg'], 'tmp') }

  after(:each) do
    File.delete(new_file) if File.exist?(new_file)
  end

  it "purges ffmpeg files that are over 4 hours old" do
    FileUtils.touch old_file, :mtime => Time.now - 5.hours
    directory = Rails.root.join('tmp')
    files = Dir.glob(directory)
    count_of_files_in_temp = Dir.glob(File.join(directory, '**', '*')).select { |file| File.file?(file) }.count
    FileCleanup.purge_files
    expect(Dir.glob(File.join(directory, '**', '*')).select { |file| File.file?(file) }.count).to eq count_of_files_in_temp - 1
    expect(files).not_to include(old_file)
  end


  it "doesn't delete files that are less than 4 hours old" do
    directory = Rails.root.join('tmp')
    files = Dir.glob(directory)
    count_of_files_in_temp = Dir.glob(File.join(directory, '**', '*')).select { |file| File.file?(file) }.count
    FileCleanup.purge_files
    expect(Dir.glob(File.join(directory, '**', '*')).select { |file| File.file?(file) }.count).to eq count_of_files_in_temp
    expect(File.exist?(new_file))
  end
end
