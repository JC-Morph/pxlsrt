require 'pxlsrt/colors'
require 'pxlsrt/helpers'
require 'pxlsrt/image'

module Pxlsrt
  class SortClass
    extend Pxlsrt::Helpers

    class << self
      def suite(input_filename, output_filename, opts = {})
        start_time = Time.now
        sorted     = call(input_filename, opts)
        end_time   = Time.now
        time_report start_time
        sorted.save output_filename
      end

      def options
        @options
      end

      private

      def time_report(start_time, end_time)
        return unless options[:verbose]
        elapsed = end_time - start_time
        report  = elapsed < 60 ?
          "Took #{elapsed.round(4)} second#{time_plural(elapsed)}." :
          minutes_and_seconds(elapsed)
        verbose report
      end

      def time_plural(elapsed)
        elapsed == 1 ? '' : 's'
      end

      def minutes_and_seconds(elapsed)
        minutes = (elapsed / 60).floor
        minutes = "#{minutes} minute#{time_plural(minutes)}"
        seconds = (elapsed % 60).round(4)
        seconds = "#{seconds} second#{time_plural(seconds)}"
        "Took #{minutes} and #{seconds}."
      end

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
