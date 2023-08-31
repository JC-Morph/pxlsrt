require 'pxlsrt/sort_class'

module Pxlsrt
  # Uses Kim Asendorf's pixel sorting algorithm, orginally written in
  # Processing. https://github.com/kimasendorf/ASDFPixelSort
  class Kim < SortClass
    class << self
      # The main attraction of the Kim class. Returns a ChunkyPNG::Image that is
      # sorted according to the options provided. Will raise any error that
      # occurs.
      def call(input, o = {})
        startTime = Time.now
        @options = opt_defaults.merge(o)
        if o.empty? || (options[:trusted] == true) || ((options[:trusted] == false) && !o.empty? && (check_options != false))
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
          progress('Sorting columns', column, png.getWidth)
          while column < png.getWidth
            x = column
            y = 0
            yend = 0
            while yend < png.getHeight
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
            progress('Sorting columns', column, png.getWidth)
          end
          progress('Sorting rows', row, png.getHeight)
          while row < png.getHeight
            x = 0
            y = row
            xend = 0
            while xend < png.getWidth
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
            progress('Sorting rows', row, png.getHeight)
          end
          endTime = Time.now
          timeElapsed = endTime - startTime
          if timeElapsed < 60
            verbose("Took #{timeElapsed.round(4)} second#{timeElapsed != 1.0 ? 's' : ''}.")
          else
            minutes = (timeElapsed / 60).floor
            seconds = (timeElapsed % 60).round(4)
            verbose("Took #{minutes} minute#{minutes != 1 ? 's' : ''} and #{seconds} second#{seconds != 1.0 ? 's' : ''}.")
          end
          verbose('Returning ChunkyPNG::Image...')
          return png.returnModified
        else
          error('Options specified do not follow the correct format.')
          raise 'Bad options'
        end
      end

      # Helper methods
      # Black
      def getFirstNotBlackX(img, x, y, blackValue)
        if x < img.getWidth
          while img[x, y] < blackValue
            x += 1
            return -1 if x >= img.getWidth
          end
        end
        x
      end

      def getFirstNotBlackY(img, x, y, blackValue)
        if y < img.getHeight
          while img[x, y] < blackValue
            y += 1
            return -1 if y >= img.getHeight
          end
        end
        y
      end

      def getNextBlackX(img, x, y, blackValue)
        x += 1
        if x < img.getWidth
          while img[x, y] > blackValue
            x += 1
            return (img.getWidth - 1) if x >= img.getWidth
          end
        end
        x - 1
      end

      def getNextBlackY(img, x, y, blackValue)
        y += 1
        if y < img.getHeight
          while img[x, y] > blackValue
            y += 1
            return (img.getHeight - 1) if y >= img.getHeight
          end
        end
        y - 1
      end

      # Brightness
      def getFirstBrightX(img, x, y, brightnessValue)
        if x < img.getWidth
          while ChunkyPNG::Color.to_hsb(img[x, y])[2] * 255 < brightnessValue
            x += 1
            return -1 if x >= img.getWidth
          end
        end
        x
      end

      def getFirstBrightY(img, x, y, brightnessValue)
        if y < img.getHeight
          while ChunkyPNG::Color.to_hsb(img[x, y])[2] * 255 < brightnessValue
            y += 1
            return -1 if y >= img.getHeight
          end
        end
        y
      end

      def getNextDarkX(img, x, y, brightnessValue)
        x += 1
        if x < img.getWidth
          while ChunkyPNG::Color.to_hsb(img[x, y])[2] * 255 > brightnessValue
            x += 1
            return (img.getWidth - 1) if x >= img.getWidth
          end
        end
        x - 1
      end

      def getNextDarkY(img, x, y, brightnessValue)
        y += 1
        if y < img.getHeight
          while ChunkyPNG::Color.to_hsb(img[x, y])[2] * 255 > brightnessValue
            y += 1
            return (img.getHeight - 1) if y >= img.getHeight
          end
        end
        y - 1
      end

      # White
      def getFirstNotWhiteX(img, x, y, whiteValue)
        if x < img.getWidth
          while img[x, y] > whiteValue
            x += 1
            return -1 if x >= img.getWidth
          end
        end
        x
      end

      def getFirstNotWhiteY(img, x, y, whiteValue)
        if y < img.getHeight
          while img[x, y] > whiteValue
            y += 1
            return -1 if y >= img.getHeight
          end
        end
        y
      end

      def getNextWhiteX(img, x, y, whiteValue)
        x += 1
        if x < img.getWidth
          while img[x, y] < whiteValue
            x += 1
            return (img.getWidth - 1) if x >= img.getWidth
          end
        end
        x - 1
      end

      def getNextWhiteY(img, x, y, whiteValue)
        y += 1
        if y < img.getHeight
          while img[x, y] < whiteValue
            y += 1
            return (img.getHeight - 1) if y >= img.getHeight
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
