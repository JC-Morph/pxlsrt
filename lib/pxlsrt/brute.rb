require 'pxlsrt/sort_class'
require 'pxlsrt/retrieve_lines'

module Pxlsrt
  # Brute sorting creates bands for sorting using a range to determine the
  # bandwidths, as opposed to smart sorting which uses edge-finding to create
  # bands.
  class Brute < SortClass
    extend RetrieveLines

    class << self
      # The main attraction of the Brute class. Returns a ChunkyPNG::Image that
      # is sorted according to the options provided. Will raise any error that
      # occurs.
      def call
        verbose 'Brute mode.'
        lines = retrieve_lines
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
        png.modified
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
