require 'pxlsrt/helpers'

module Pxlsrt
  # "Line" operations used on arrays f colors.
  class Lines
    class << self
      # Some fancy rearranging.
      # [a, b, c, d, e] -> [d, b, a, c, e]
      # [a, b, c, d]    -> [c, a, b, d]
      def middlate(arr)
        (0...arr.size).each.with_object([]) do |val, result|
          idx = if (arr.size + val).odd?
                  0.5 * (arr.size + val - 1)
                else
                  0.5 * (arr.size - val) - 1
                end
          result[idx] = arr[val]
        end
      end

      # Some fancy unrearranging.
      # [d, b, a, c, e] -> [a, b, c, d, e]
      # [c, a, b, d]    -> [a, b, c, d]
      def reverse_middlate(arr)
        (0...arr.size).each.with_object([]) do |val, result|
          idx = case val <=> ((arr.size / 2.0).ceil - 1)
          when -1
            arr.size - (val * 2) - 2
          when 0
            0
          when 1
            (2 * val) - arr.size.succ
          end
          result[idx] = arr[val]
        end
      end

      # Handle middlate requests
      def handle_middlate(arr, middle)
        middle_int = Integer(middle, exception: false)
        if [nil, 0].include?(middle_int)
          return middlate(arr) if middle.to_s[/^(middle|)$/]
          return arr
        end
        middlate_method = "#{middle_int < 0 ? 'reverse_' : ''}middlate"
        (0...middle_int.abs).each.with_object([]) do |_, arr|
          arr = send(middlate_method, arr)
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
