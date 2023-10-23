require 'oily_png'
require 'pxlsrt/helpers'

module Pxlsrt
  # Includes color operations.
  class Colors
    Color = ChunkyPNG::Color
    # List of sorting methods.
    METHODS = %i[
      sum-rgb
      sum-rgba
      red
      yellow
      green
      cyan
      blue
      magenta
      hue
      saturation
      brightness
      sum-hsb
      sum-hsba
      uniqueness
      luma
      alpha
      random
      none
    ].freeze

    class << self
      # Sorts an array of colors based on a method.
      def pixel_sort(list, how, reverse)
        Pxlsrt::Helpers.error(list) if list.empty?
        mod = modifiers(how, reverse)
        return mod if mod.is_a?(Array)

        base = if reverse.zero?
                 1
               elsif reverse == 1
                 -1
               else
                 [-1, 1].sample
               end
        list.sort_by {|pxl| base * mod.call(pxl) }
      end

      private

      def modifiers( how, reverse )
        case how
        when 'sum-rgb'
          ->(pxl) { Color.r(pxl) + Color.g(pxl) + Color.b(pxl) }
        when 'sum-rgba'
          ->(pxl) do
            Color.r(pxl) + Color.g(pxl) + Color.b(pxl) + Color.a(pxl)
          end
        when 'red'
          ->(pxl) { Color.r(pxl) }
        when 'yellow'
          ->(pxl) { Color.r(pxl) + Color.g(pxl) }
        when 'green'
          ->(pxl) { Color.g(pxl) }
        when 'cyan'
          ->(pxl) { Color.g(pxl) + Color.b(pxl) }
        when 'blue'
          ->(pxl) { Color.b(pxl) }
        when 'magenta'
          ->(pxl) { Color.r(pxl) + Color.b(pxl) }
        when 'hue'
          ->(pxl) { Color.to_hsb(pxl)[0] % 360 }
        when 'saturation'
          ->(pxl) { Color.to_hsb(pxl)[1] }
        when 'brightness'
          ->(pxl) { Color.to_hsb(pxl)[2] }
        when 'sum-hsb'
          ->(pxl) do
            hsb = Color.to_hsb(pxl)
            (hsb[0] % 360) / 360.0 + hsb[1] + hsb[2]
          end
        when 'sum-hsba'
          ->(pxl) do
            hsb = Color.to_hsb(pxl)
            (hsb[0] % 360) / 360.0 + hsb[1] + hsb[2] + Color.a(pxl) / 255.0
          end
        when 'uniqueness'
          avg = [color_average(list, true)]
          ->(pxl) { color_uniqueness(pxl, avg, true) }
        when 'luma'
          ->(pxl) do
            Color.r(pxl) * 0.2126 +
              Color.g(pxl) * 0.7152 +
              Color.b(pxl) * 0.0722 +
              Color.a(pxl)
          end
        when 'alpha'
          ->(pxl) { Color.a(pxl) }
        when 'random'
          list.shuffle
        when 'none'
          reverse == 1 ? list.reverse : list
        end
      end

      # Uses a combination of color averaging and color distance to find how
      # "unique" a color is.
      def color_uniqueness(pxl, pxl_avg, chunky = false)
        color_distance(pxl, color_average(pxl_avg, chunky), chunky)
      end

      # Averages an array of RGB-like arrays.
      def color_average(arr, chunky = false)
        return arr.first if arr.size == 1
        Pxlsrt::Helpers.verbose(ca) if ca.empty?
        if chunky
          colors = [:r, :g, :b, :a].map do |color|
            totals = arr.map { Color.send(color, pxl) }.reduce(:+)
            (totals.to_f / arr.size).to_i
          end
          Color.rgba(*colors)
        else
          4.times.map do |idx|
            totals = arr.map { pxl[idx] }.reduce(:+)
            (totals.to_f / arr.size).to_i
          end
        end
      end

      # Determines color distance from each other using the Pythagorean theorem.
      def color_distance(pxl_a, pxl_b, chunky = false)
        diffs = if chunky
                  [:r, :g, :b, :a].map do |color|
                    (Color.send(color, pxl_a) - Color.send(color, pxl_b))**2
                  end
                else
                  4.times.map {|idx| (pxl_a[idx] - pxl_b[idx])**2 }
                end
        Math.sqrt diffs.reduce(:+)
      end
    end
  end
end
