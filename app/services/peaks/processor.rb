require "ruby-audio"

module Peaks
  class Processor
    def initialize(peaks_path, samples)
      @peaks_path = peaks_path
      @samples = samples
      @converter = Peaks::Converter.new()
    end

    def generate(remote_file, peaks_filename)
      raw_path = @converter.fetch(remote_file)

      puts "tmp path: #{raw_path}"

      peaks = expand(JsonWaveform.generate(raw_path, samples: 1000, method: :peak, width: 1650)).to_json

      peaks_path = "#{@peaks_path}/#{peaks_filename}"

      puts "writing peaks to #{peaks_path}"

      open(peaks_path, "wb", 0755) do |f|
        f.puts peaks
      end

      puts "writing peaks to #{peaks_path}"

      peaks_path
    end

    def expand(peaks)
      max = peaks.max

      puts "comp: 1/#{max} = #{1/max}"

      peaks.collect { |pk| (1/max) * pk }
    end
  end
end
