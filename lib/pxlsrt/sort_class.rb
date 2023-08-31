require 'pxlsrt/colors'
require 'pxlsrt/helpers'
require 'pxlsrt/image'

module Pxlsrt
  class SortClass
    extend Pxlsrt::Helpers

    class << self
      def suite(input_filename, output_filename, opts = {})
        kml = call(input_filename, opts)
        kml.save(output_filename) unless kml.nil?
      end

      def options
        @options
      end

      private

      def common_defaults
        {
          reverse: false,
          smooth:  false,
          method:  'sum-rgb',
          middle:  false
        }.merge shared_defaults
      end

      def common_rules
        {
          reverse: :anything,
          smooth:  bool_rule,
          method:  Pxlsrt::Colors::METHODS,
          middle:  :anything
        }.merge shared_rules
      end

      def shared_defaults
        {verbose: false, trusted: false}
      end

      def shared_rules
        {verbose: bool_rule, trusted: bool_rule}
      end

      def bool_rule
        [false, true]
      end
    end
  end
end
