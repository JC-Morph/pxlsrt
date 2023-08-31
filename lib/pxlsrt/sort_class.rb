require 'pxlsrt/colors'
require 'pxlsrt/helpers'
require 'pxlsrt/image'

module Pxlsrt
  class SortClass
    extend Pxlsrt::Helpers

    class << self
      def suite(input, output_filename, opts = {})
        def_options(opts)
        check_input(input)
        start_time = Time.now
        call.save output_filename
        end_time   = Time.now
        time_report(start_time, end_time)
      end

      def options
        @options
      end

      def png
        @png
      end

      private

      def def_options(opts)
        @options = opt_defaults.merge(opts)
        valid    = opts.empty? || options[:trusted] || (check_options == false)
        option_error unless valid
        verbose 'Options are all good.'
      end

      def option_error
        error 'Options specified do not follow the correct format.'
        raise 'Bad options'
      end

      def check_input(input)
        @png = input
        input_type_error unless [String, ChunkyPNG::Image].include?(png.class)
        return initialize_png unless png.class == String
        input_existence_error unless File.exists?(png)
        verbose 'Getting image from file...'
        input_png_error unless Pxlsrt::Colors.isPNG?(png)
        @png = ChunkyPNG::Image.from_file(png)
        initialize_png
      end

      def initialize_png
        verbose 'Creating Pxlsrt::Image object'
        @png = Pxlsrt::Image.new(png)
      end

      def input_type_error
        error "#{png} is not a filename or ChunkyPNG::Image"
        raise 'Invalid input (must be filename or ChunkyPNG::Image)'
      end

      def input_existence_error
        error "#{png} doesn't exist!"
        raise "File doesn't exist"
      end

      def input_png_error
        error "#{png} is not a valid PNG."
        raise 'Invalid PNG'
      end

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
