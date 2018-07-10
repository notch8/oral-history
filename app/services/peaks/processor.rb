require "ruby-audio"

module Peaks
  class Processor
    def initialize(peaks_path, opts = {})
      @peaks_path = peaks_path
      @samples = opts[:samples] || 1000
      @should_expand = opts[:should_expand] || true
      @processor_method = opts[:processor_method] || :peak
      @width = opts[:width] || 1650

      @converter = Peaks::Converter.new()
    end

    # generate downloads and generates the peak files
    def generate(remote_file, peaks_filename)
      raw_path = @converter.fetch(remote_file)
      peaks_path = "#{@peaks_path}/#{peaks_filename}"

      raw_peaks = JsonWaveform.generate(
        raw_path,
        samples: @samples,
        method: @processor_method,
        width: @width
      )

      peaks = @should_expand ? expand(raw_peaks) : raw_peaks

      # TODO: this needs to be swapped for generic "writer" or a code block
      open(peaks_path, "wb", 0755) do |f|
        f.puts peaks.to_json
      end

      # TODO: this needs to be cleaner - look into TmpDir accepting blocks
      # cleanup tmpdir
      system("rm -rf #{raw_path.gsub('/audio.wave', '')}")

      peaks_path
    end

    # takes a solr document and attempts to create the peaks file
    def from_solr_document(doc)
      return unless doc["children_t"]

      # children_t is where all the non-indexed fields (i.e. audo_url) lives
      doc["children_t"].each do |child|
        next unless JSON.parse(child)["url_t"]

        generate(JSON.parse(child)["url_t"], "#{JSON.parse(child)["id_t"].gsub('/', '-')}.json")
      end
    end

    # expand attempts to normalize the peak data to be more aesthetically interesting
    def expand(peaks)
      max = peaks.max

      peaks.collect { |pk| (1/max) * pk }
    end
  end
end
