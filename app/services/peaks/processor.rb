require 'ruby-audio'
require 'shellwords'

module Peaks
  class Processor
    def initialize(opts = {})
      @samples = opts[:samples] || 1000
      @should_expand = opts[:should_expand] || true
      @processor_method = opts[:processor_method] || :peak
      @width = opts[:width] || 1650

      @converter = Peaks::Converter.new()
    end

    # generate downloads and generates the peak files
    def generate(remote_file)
      raw_path = @converter.fetch(remote_file)

      raw_peaks = JsonWaveform.generate(
        raw_path,
        samples: @samples,
        method: @processor_method,
        width: @width
      )

      peaks = @should_expand ? expand(raw_peaks) : raw_peaks

      peaks
    ensure
      sanitized_raw_path = Shellwords.escape(raw_path.gsub('/audio.wave', ''))
      system("rm -rf #{sanitized_raw_path}") if raw_path
    end

    # takes a solr document and attempts to create the peaks file
    def from_solr_document(doc)
      return unless doc.attributes["peaks_t"]
      begin
        # children_t is where all the non-indexed fields (i.e. audo_url) lives
        # peaks_t is a duplicate of non-indexed fields for peak generation
        doc.attributes["peaks_t"].each_with_index do |child, i|
          raw = JSON.parse(child)
          next unless raw["url_t"]

          puts "Processing #{raw["url_t"]}"
          raw["peaks"] = generate(raw["url_t"])

          doc.attributes["peaks_t"][i] = raw.to_json
        end

        doc.index_record
      rescue => exception
        Rollbar.error('Error processing peaks', exception)
      end
    end

    # expand attempts to normalize the peak data to be more aesthetically interesting
    def expand(peaks)
      max = peaks.max

      peaks.collect { |pk| (1/max) * pk }
    end
  end
end
