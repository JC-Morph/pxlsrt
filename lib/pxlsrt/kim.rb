require 'pxlsrt/sort_class'

module Pxlsrt
  # Uses Kim Asendorf's pixel sorting algorithm, orginally written in
  # Processing. https://github.com/kimasendorf/ASDFPixelSort
  class Kim < SortClass
    class << self
      # The main attraction of the Kim class. Returns a ChunkyPNG::Image that is
      # sorted according to the options provided. Will raise any error that
      # occurs.
      def call(input)
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
        verbose('Kim Asendorf mode.')
        verbose('Creating Pxlsrt::Image object')
        png = Pxlsrt::Image.new(input)
        column = 0
        row = 0
        options[:value] ||= ChunkyPNG::Color.rgba(11, 220, 0, 1) if options[:method] == 'black'
        options[:value] ||= 60 if options[:method] == 'brightness'
        options[:value] ||= ChunkyPNG::Color.rgba(57, 167, 192, 1) if options[:method] == 'white'
        progress('Sorting columns', column, png.width)
        while column < png.width
          x = column
          y = 0
          yend = 0
          while yend < png.height
            case options[:method]
            when 'black'
              y = getFirstNotBlackY(png, x, y, options[:value])
              yend = getNextBlackY(png, x, y, options[:value])
            when 'brightness'
              y = getFirstBrightY(png, x, y, options[:value])
              yend = getNextDarkY(png, x, y, options[:value])
            when 'white'
              y = getFirstNotWhiteY(png, x, y, options[:value])
              yend = getNextWhiteY(png, x, y, options[:value])
            end
            break if y < 0
            sortLength = yend - y
            unsorted = []
            sorted = []
            (0...sortLength).each do |i|
              unsorted[i] = png[x, y + i]
            end
            sorted = unsorted.sort
            (0...sortLength).each do |i|
              png[x, y + i] = sorted[i]
            end
            y = yend + 1
          end
          column += 1
          progress('Sorting columns', column, png.width)
        end
        progress('Sorting rows', row, png.height)
        while row < png.height
          x = 0
          y = row
          xend = 0
          while xend < png.width
            case options[:method]
            when 'black'
              x = getFirstNotBlackX(png, x, y, options[:value])
              xend = getNextBlackX(png, x, y, options[:value])
            when 'brightness'
              x = getFirstBrightX(png, x, y, options[:value])
              xend = getNextDarkX(png, x, y, options[:value])
            when 'white'
              x = getFirstNotWhiteX(png, x, y, options[:value])
              xend = getNextWhiteX(png, x, y, options[:value])
            end
            break if x < 0
            sortLength = xend - x
            unsorted = []
            sorted = []
            (0...sortLength).each do |i|
              unsorted[i] = png[x + i, y]
            end
            sorted = unsorted.sort
            (0...sortLength).each do |i|
              png[x + i, y] = sorted[i]
            end
            x = xend + 1
          end
          row += 1
          progress('Sorting rows', row, png.height)
        end
        verbose('Returning ChunkyPNG::Image...')
        png.modified
      end

      # Helper methods
      # Black
      def getFirstNotBlackX(img, x, y, blackValue)
        if x < img.width
          while img[x, y] < blackValue
            x += 1
            return -1 if x >= img.width
          end
        end
        x
      end

      def getFirstNotBlackY(img, x, y, blackValue)
        if y < img.height
          while img[x, y] < blackValue
            y += 1
            return -1 if y >= img.height
          end
        end
        y
      end

      def getNextBlackX(img, x, y, blackValue)
        x += 1
        if x < img.width
          while img[x, y] > blackValue
            x += 1
            return (img.width - 1) if x >= img.width
          end
        end
        x - 1
      end

      def getNextBlackY(img, x, y, blackValue)
        y += 1
        if y < img.height
          while img[x, y] > blackValue
            y += 1
            return (img.height - 1) if y >= img.height
          end
        end
        y - 1
      end

      # Brightness
      def getFirstBrightX(img, x, y, brightnessValue)
        if x < img.width
          while ChunkyPNG::Color.to_hsb(img[x, y])[2] * 255 < brightnessValue
            x += 1
            return -1 if x >= img.width
          end
        end
        x
      end

      def getFirstBrightY(img, x, y, brightnessValue)
        if y < img.height
          while ChunkyPNG::Color.to_hsb(img[x, y])[2] * 255 < brightnessValue
            y += 1
            return -1 if y >= img.height
          end
        end
        y
      end

      def getNextDarkX(img, x, y, brightnessValue)
        x += 1
        if x < img.width
          while ChunkyPNG::Color.to_hsb(img[x, y])[2] * 255 > brightnessValue
            x += 1
            return (img.width - 1) if x >= img.width
          end
        end
        x - 1
      end

      def getNextDarkY(img, x, y, brightnessValue)
        y += 1
        if y < img.height
          while ChunkyPNG::Color.to_hsb(img[x, y])[2] * 255 > brightnessValue
            y += 1
            return (img.height - 1) if y >= img.height
          end
        end
        y - 1
      end

      # White
      def getFirstNotWhiteX(img, x, y, whiteValue)
        if x < img.width
          while img[x, y] > whiteValue
            x += 1
            return -1 if x >= img.width
          end
        end
        x
      end

      def getFirstNotWhiteY(img, x, y, whiteValue)
        if y < img.height
          while img[x, y] > whiteValue
            y += 1
            return -1 if y >= img.height
          end
        end
        y
      end

      def getNextWhiteX(img, x, y, whiteValue)
        x += 1
        if x < img.width
          while img[x, y] < whiteValue
            x += 1
            return (img.width - 1) if x >= img.width
          end
        end
        x - 1
      end

      def getNextWhiteY(img, x, y, whiteValue)
        y += 1
        if y < img.height
          while img[x, y] < whiteValue
            y += 1
            return (img.height - 1) if y >= img.height
          end
        end
        y - 1
      end

      private

      def opt_defaults
        {
          method: 'brightness',
          value:  false
        }.merge shared_defaults
      end

      def opt_rules
        {
          method: %w[brightness black white],
          value:  [false, {class: [Integer]}]
        }.merge shared_rules
      end
    end
  end
end
