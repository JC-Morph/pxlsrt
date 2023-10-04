require 'pxlsrt/lines'
require 'pxlsrt/line_operations'
require 'pxlsrt/sort_class'

module Pxlsrt
  # Brute sorting creates bands for sorting using a range to determine the
  # bandwidths, as opposed to smart sorting which uses edge-finding to create
  # bands.
  class Brute < SortClass
    extend LineOperations

    class << self
      # The main attraction of the Brute class. Returns a ChunkyPNG::Image that
      # is sorted according to the options provided. Will raise any error that
      # occurs.
      def call
        verbose 'Brute mode.'
        iterator.each.with_index do |val, idx|
          line = lines[val]
          divisions = Pxlsrt::Lines.random_slices(line.size, options[:min], options[:max])
          new_line  = divisions.each.with_object([]) do |division, arr|
            band = line[division[0]..division[1]]
            arr.concat handle_pixel_sort(band)
          end
          replace_lines(val, new_line)
          progress('Dividing and sorting lines', idx.succ, total)
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
