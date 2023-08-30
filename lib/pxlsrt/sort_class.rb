require 'pxlsrt/helpers'

module Pxlsrt
  class SortClass
    extend Pxlsrt::Helpers

    def self.options
      @options
    end

    def self.suite(input_filename, output_filename, opts = {})
      kml = call(input_filename, opts)
      kml.save(output_filename) unless kml.nil?
    end
  end
end
