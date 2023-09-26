require 'pxlsrt/helpers'

module Pxlsrt
  # "Line" operations used on arrays f colors.
  class Lines
    class << self
      # ChunkyPNG's rotation was a little slow and doubled runtime.
      # This "rotates" an array, based on the width and height.
      # It uses math and it's really cool, trust me.
      def rotateImage(what, width, height, a)
        nu = []
        case a
        when 0, 360, 4
          nu = what
        when 1, 90
          (0...what.length).each do |xy|
            idx = ((height - 1) - (xy / width).floor) + (xy % width) * height
            nu[idx] = what[xy]
          end
        when 2, 180
          nu = what.reverse
        when 3, 270
          (0...what.length).each do |xy|
            idx = (xy / width).floor + ((width - 1) - (xy % width)) * height
            nu[idx] = what[xy]
          end
        end
        nu
      end

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

      ##
      # Uses math to turn an array into an array of diagonals.
      def getDiagonals(array, width, height)
        dias = {}
        ((1 - height)...width).each do |x|
          z = []
          (0...height).each do |y|
            if (x + (width + 1) * y).between?(width * y, (width * (y + 1) - 1))
              z.push(array[(x + (width + 1) * y)])
            end
          end
          dias[x.to_s] = z
        end
        dias
      end
    end
  end
end
