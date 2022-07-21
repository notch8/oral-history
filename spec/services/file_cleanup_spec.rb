require 'rails_helper'

RSpec.describe FileCleanup, clean: true do
  it "purges files" do
    tmp_file = Tempfile.create(['tmp_1', '.ffmpeg'], 'tmp')
    dir = Rails.root.join('tmp')
    files = Dir.glob(dir)
    file_count = Dir[File.join(dir, '**', '*')].count { |file| File.file?(file) }
    new_time = Time.now - 5.hours
    FileUtils.touch tmp_file, :mtime => new_time
    FileCleanup.purge_files
    expect(Dir[File.join(dir, '**', '*')].count { |file| File.file?(file) }).to eq file_count - 1
    expect(files).not_to include(tmp_file)
  end
end
