require 'pxlsrt/sort_class'

module Pxlsrt
  # Brute sorting creates bands for sorting using a range to determine the
  # bandwidths, as opposed to smart sorting which uses edge-finding to create
  # bands.
  class Brute < SortClass
    class << self
      # The main attraction of the Brute class. Returns a ChunkyPNG::Image that
      # is sorted according to the options provided. Will raise any error that
      # occurs.
      def call(input, o = {})
        @options = opt_defaults.merge(o)
        if o.empty? || (options[:trusted] == true) || ((options[:trusted] == false) && !o.empty? && (check_options != false))
          verbose('Options are all good.')
          if input.class == String
            verbose('Getting image from file...')
            if File.file?(input)
              if Pxlsrt::Colors.isPNG?(input)
                input = ChunkyPNG::Image.from_file(input)
              else
                error("File #{input} is not a valid PNG.")
                raise 'Invalid PNG'
              end
            else
              error("File #{input} doesn't exist!")
              raise "File doesn't exist"
            end
          elsif input.class != ChunkyPNG::Image
            error('Input is not a filename or ChunkyPNG::Image')
            raise 'Invalid input (must be filename or ChunkyPNG::Image)'
          end
          verbose('Brute mode.')
          verbose('Creating Pxlsrt::Image object')
          png = Pxlsrt::Image.new(input)
          if !options[:vertical] && !options[:diagonal]
            verbose('Retrieving rows')
            lines = png.rows
          elsif options[:vertical] && !options[:diagonal]
            verbose('Retrieving columns')
            lines = png.columns
          elsif !options[:vertical] && options[:diagonal]
            verbose('Retrieving diagonals')
            lines = png.diagonals
          elsif options[:vertical] && options[:diagonal]
            verbose('Retrieving diagonals')
            lines = png.diagonals(reverse: true)
          end
          iterator = if !options[:diagonal]
                       0...(lines.length)
                     else
                       lines.keys
                     end
          prr = 0
          len = iterator.to_a.length
          progress('Dividing and pixel sorting lines', prr, len)
          iterator.each do |k|
            line = lines[k]
            divisions = Pxlsrt::Lines.randomSlices(line.length, options[:min], options[:max])
            newLine = []
            divisions.each do |division|
              band = line[division[0]..division[1]]
              newLine.concat(handlePixelSort(band, options))
            end
            if !options[:diagonal]
              png.replace_rows(k, newLine) unless options[:vertical]
              png.replace_columns(k, newLine) if options[:vertical]
            else
              png.replaceDiagonal(k, newLine) unless options[:vertical]
              png.replaceRDiagonal(k, newLine) if options[:vertical]
            end
            prr += 1
            progress('Dividing and pixel sorting lines', prr, len)
          end
          verbose('Returning ChunkyPNG::Image...')
          return png.modified
        else
          error('Options specified do not follow the correct format.')
          raise 'Bad options'
        end
      end

      private

      def opt_defaults
        {
          vertical: false,
          diagonal: false,
          min:      Float::INFINITY,
          max:      Float::INFINITY
        }.merge common_defaults
      end

      def opt_rules
        {
          vertical: bool_rule,
          diagonal: bool_rule,
          min:      [Float::INFINITY, {class: [Integer]}],
          max:      [Float::INFINITY, {class: [Integer]}]
        }.merge common_rules
      end
    end
  end
end
