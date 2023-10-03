require 'oily_png'
require 'pxlsrt/helpers'

module Pxlsrt
  ##
  # Includes color operations.
  class Colors
    ##
    # List of sorting methods.
    METHODS = ['sum-rgb', 'red', 'green', 'blue', 'sum-hsb', 'hue', 'saturation', 'brightness', 'uniqueness', 'luma', 'random', 'cyan', 'magenta', 'yellow', 'alpha', 'sum-rgba', 'sum-hsba', 'none'].freeze
    ##
    # Converts a ChunkyPNG pixel into an array of the red, green, blue, and alpha values
    def self.getRGBA(pxl)
      [ChunkyPNG::Color.r(pxl), ChunkyPNG::Color.g(pxl), ChunkyPNG::Color.b(pxl), ChunkyPNG::Color.a(pxl)]
    end

    ##
    # Check if file is a PNG image. ChunkyPNG only works with PNG images. Eventually, I might use conversion tools to add support, but not right now.
    def self.isPNG?(path)
      File.open(path, 'rb').read(9).include?('PNG')
    end

    ##
    # Averages an array of RGB-like arrays.
    def self.colorAverage(ca, chunky = false)
      return ca.first if ca.length == 1
      Pxlsrt::Helpers.verbose(ca) if ca.empty?
      if !chunky
        r = ((ca.collect { |c| c[0] }).inject { |sum, el| sum + el }).to_f / ca.size
        g = ((ca.collect { |c| c[1] }).inject { |sum, el| sum + el }).to_f / ca.size
        b = ((ca.collect { |c| c[2] }).inject { |sum, el| sum + el }).to_f / ca.size
        a = ((ca.collect { |c| c[3] }).inject { |sum, el| sum + el }).to_f / ca.size
        return [r.to_i, g.to_i, b.to_i, a.to_i]
      else
        r = ((ca.collect { |c| ChunkyPNG::Color.r(c) }).inject { |sum, el| sum + el }).to_f / ca.size
        g = ((ca.collect { |c| ChunkyPNG::Color.g(c) }).inject { |sum, el| sum + el }).to_f / ca.size
        b = ((ca.collect { |c| ChunkyPNG::Color.b(c) }).inject { |sum, el| sum + el }).to_f / ca.size
        a = ((ca.collect { |c| ChunkyPNG::Color.a(c) }).inject { |sum, el| sum + el }).to_f / ca.size
        return ChunkyPNG::Color.rgba(r.to_i, g.to_i, b.to_i, a.to_i)
      end
    end

    ##
    # Determines color distance from each other using the Pythagorean theorem.
    def self.colorDistance(c1, c2, chunky = false)
      if !chunky
        Math.sqrt((c1[0] - c2[0])**2 + (c1[1] - c2[1])**2 + (c1[2] - c2[2])**2 + (c1[3] - c2[3])**2)
      else
        Math.sqrt((ChunkyPNG::Color.r(c1) - ChunkyPNG::Color.r(c2))**2 + (ChunkyPNG::Color.g(c1) - ChunkyPNG::Color.g(c2))**2 + (ChunkyPNG::Color.b(c1) - ChunkyPNG::Color.b(c2))**2 + (ChunkyPNG::Color.a(c1) - ChunkyPNG::Color.a(c2))**2)
      end
    end

    ##
    # Uses a combination of color averaging and color distance to find how "unique" a color is.
    def self.colorUniqueness(c, ca, chunky = false)
      Pxlsrt::Colors.colorDistance(c, Pxlsrt::Colors.colorAverage(ca, chunky), chunky)
    end

    ##
    # Sorts an array of colors based on a method.
    # Available methods:
    # * sum-rgb (default)
    # * sum-rgba
    # * red
    # * yellow
    # * green
    # * cyan
    # * blue
    # * magenta
    # * hue
    # * saturation
    # * brightness
    # * sum-hsb
    # * sum-hsba
    # * uniqueness
    # * luma
    # * random
    # * alpha
    # * none
    def self.pixelSort(list, how, reverse)
      mhm = []
      Pxlsrt::Helpers.error(list) if list.empty?
      k = if reverse.zero?
            1
          elsif reverse == 1
            -1
          else
            [-1, 1].sample
          end
      case how.downcase
      when 'sum-rgb'
        mhm = list.sort_by { |c| k * (ChunkyPNG::Color.r(c) + ChunkyPNG::Color.g(c) + ChunkyPNG::Color.b(c)) }
      when 'sum-rgba'
        mhm = list.sort_by { |c| k * (ChunkyPNG::Color.r(c) + ChunkyPNG::Color.g(c) + ChunkyPNG::Color.b(c) + ChunkyPNG::Color.a(c)) }
      when 'red'
        mhm = list.sort_by { |c| k * ChunkyPNG::Color.r(c) }
      when 'yellow'
        mhm = list.sort_by { |c| k * (ChunkyPNG::Color.r(c) + ChunkyPNG::Color.g(c)) }
      when 'green'
        mhm = list.sort_by { |c| k * ChunkyPNG::Color.g(c) }
      when 'cyan'
        mhm = list.sort_by { |c| k * (ChunkyPNG::Color.g(c) + ChunkyPNG::Color.b(c)) }
      when 'blue'
        mhm = list.sort_by { |c| k * ChunkyPNG::Color.b(c) }
      when 'magenta'
        mhm = list.sort_by { |c| k * (ChunkyPNG::Color.r(c) + ChunkyPNG::Color.b(c)) }
      when 'hue'
        mhm = list.sort_by { |c| k * (ChunkyPNG::Color.to_hsb(c)[0] % 360) }
      when 'saturation'
        mhm = list.sort_by { |c| k * ChunkyPNG::Color.to_hsb(c)[1] }
      when 'brightness'
        mhm = list.sort_by { |c| k * ChunkyPNG::Color.to_hsb(c)[2] }
      when 'sum-hsb'
        mhm = list.sort_by do |c|
          hsb = ChunkyPNG::Color.to_hsb(c)
          k * ((hsb[0] % 360) / 360.0 + hsb[1] + hsb[2])
        end
      when 'sum-hsba'
        mhm = list.sort_by do |c|
          hsb = ChunkyPNG::Color.to_hsb(c)
          k * ((hsb[0] % 360) / 360.0 + hsb[1] + hsb[2] + ChunkyPNG::Color.a(c) / 255.0)
        end
      when 'uniqueness'
        avg = Pxlsrt::Colors.colorAverage(list, true)
        mhm = list.sort_by { |c| k * Pxlsrt::Colors.colorUniqueness(c, [avg], true) }
      when 'luma'
        mhm = list.sort_by { |c| k * (ChunkyPNG::Color.r(c) * 0.2126 + ChunkyPNG::Color.g(c) * 0.7152 + ChunkyPNG::Color.b(c) * 0.0722 + ChunkyPNG::Color.a(c)) }
      when 'random'
        mhm = list.shuffle
      when 'alpha'
        mhm = list.sort_by { |c| k * ChunkyPNG::Color.a(c) }
      when 'none'
        mhm = if k == -1
                list.reverse
              else
                list
              end
      else
        mhm = list.sort_by { |c| k * (ChunkyPNG::Color.r(c) + ChunkyPNG::Color.g(c) + ChunkyPNG::Color.b(c)) }
      end
      mhm
    end

    ##
    # Turns an RGB-like array into ChunkyPNG's color
    def self.arrayToRGBA(a)
      ChunkyPNG::Color.rgba(a[0], a[1], a[2], a[3])
    end
  end
end
