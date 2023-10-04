require 'pxlsrt/helpers'

module Pxlsrt
  # "Line" operations used on arrays f colors.
  class Lines
    class << self
      # Some fancy rearranging.
      # [a, b, c, d, e] -> [d, b, a, c, e]
      # [a, b, c, d] -> [c, a, b, d]
      def middlate(arr)
        a = []
        (0...arr.length).each do |e|
          if (arr.length + e).odd?
            a[0.5 * (arr.length + e - 1)] = arr[e]
          elsif (arr.length + e).even?
            a[0.5 * (arr.length - e) - 1] = arr[e]
          end
        end
        a
      end

      # Some fancy unrearranging.
      # [d, b, a, c, e] -> [a, b, c, d, e]
      # [c, a, b, d] -> [a, b, c, d]
      def reverseMiddlate(arr)
        a = []
        (0...arr.length).each do |e|
          if e == ((arr.length / 2.0).ceil - 1)
            a[0] = arr[e]
          elsif e < ((arr.length / 2.0).ceil - 1)
            a[arr.length - 2 * e - 2] = arr[e]
          elsif e > ((arr.length / 2.0).ceil - 1)
            a[2 * e - arr.length + 1] = arr[e]
          end
        end
        a
      end

      # Handle middlate requests
      def handleMiddlate(arr, d)
        n = Pxlsrt::Helpers.isNumeric?(d)
        if n && d.to_i > 0
          k = arr
          (0...d.to_i).each do |_l|
            k = middlate(k)
          end
          return k
        elsif n && d.to_i < 0
          k = arr
          (0...d.to_i.abs).each do |_l|
            k = reverseMiddlate(k)
          end
          return k
        elsif (d == '') || (d == 'middle')
          return middlate(arr)
        else
          return arr
        end
      end

      # Outputs random slices of an array.
      # Because of the requirements of pxlsrt, it doesn't actually slice the
      # array, but returns a range-like array. Example:
      # [[0, 5], [6, 7], [8, 10]]
      def random_slices(main_size, min_size, max_size)
        return [[0, 0]] if main_size <= 1
        min    = [[min_size, main_size, max_size].min, 1].max
        max    = [[[min_size, max_size].max, main_size].min, 1].max
        slices = [[0, rand(min..max) - 1]]
        while true
          last      = slices.last.last
          last_succ = last.succ
          if (main_size - last) > max
            slices << [last_succ, last + rand(min..max)]
          else
            slices << [last_succ, main_size - 1] if last_succ < main_size
            return slices
          end
        end
      end

      # Uses math to turn an array of rows into an array of diagonals.
      def get_diagonals(rows, width, height)
        ((1 - height)...width).each_with_object({}) do |x_coord, hsh|
          diag = get_diagonal(x_coord, width, height)
          hsh[x_coord.to_s] = diag.map {|idx| rows[idx] }
        end
      end

      def get_diagonal(x_coord, width, height)
        (0...height).each_with_object([]) do |y_coord, arr|
          idx    = x_coord + (width + 1) * y_coord
          bounds = [width * y_coord, (width * y_coord.succ) - 1]
          arr << idx if idx.between?(*bounds)
        end
      end
    end
  end
end
