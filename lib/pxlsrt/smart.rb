require 'pxlsrt/sort_class'
require 'pxlsrt/line_operations'

module Pxlsrt
  # Smart sorting uses sorted-finding algorithms to create bands to sort,
  # as opposed to brute sorting which doesn't care for the content or
  # sorteds, just a specified range to create bands.
  class Smart < SortClass
    extend LineOperations

    class << self
      # The main attraction of the Smart class. Returns a ChunkyPNG::Image that
      # is sorted according to the options provided. Will raise any error that
      # occurs.
      def call
        verbose 'Smart mode.'
        verbose 'Retrieving edges'
        png.sobels
        iterator.each.with_index do |val, idx|
          line = lines[val]
          progress('Dividing and sorting lines', idx, total)
          divisions = []
          division = []
          if line.size > 1
            (0...line.length).each do |pixel|
              direction = diagonal ? :diagonal : :horizontal
              if vertical
                direction = diagonal ? :rDiagonal : :vertical
              end
              coords    = png.send("#{direction}_coords", val, pixel)
              pxl_sobel = png.sobel_and_color(*coords.values)
              if division.empty? || below_threshold?(pxl_sobel['sobel'], division)
                division.push(pxl_sobel)
              else
                divisions.push(division)
                division = [pxl_sobel]
              end
              if pixel == line.size - 1
                divisions.push(division)
                division = []
              end
            end
          end
          new_line = divisions.each.with_object([]) do |band, arr|
            band = band.map {|pxl_sobel| pxl_sobel['color'] }
            arr.concat handlePixelSort(band, options)
          end
          replace_lines(val, new_line)
        end
        verbose('Returning ChunkyPNG::Image...')
        png.modified
      end

      private

      def below_threshold?(sobel, division)
        sobel -= division.last['sobel'] unless options[:absolute]
        sobel <= options[:threshold]
      end

      def opt_defaults
        {
          vertical:  false,
          diagonal:  false,
          absolute:  false,
          threshold: 20
        }.merge common_defaults
      end

      def opt_rules
        {
          vertical:  bool_rule,
          diagonal:  bool_rule,
          absolute:  bool_rule,
          threshold: [{class: [Float, Integer]}]
        }.merge common_rules
      end
    end
  end
end
