require 'oily_png'
require 'pxlsrt/colors'
require 'pxlsrt/image'
require 'pxlsrt/helpers'

module Pxlsrt
  # Smart sorting uses sorted-finding algorithms to create bands to sort,
  # as opposed to brute sorting which doesn't care for the content or
  # sorteds, just a specified range to create bands.
  class Smart
    extend Pxlsrt::Helpers

    def self.options
      @options
    end

    # Uses Pxlsrt::Smart.smart to input and output from pne method.
    def self.suite(inputFileName, outputFileName, o = {})
      kml = smart(inputFileName, o)
      kml.save(outputFileName) if contented(kml)
    end

    ##
    # The main attraction of the Smart class. Returns a ChunkyPNG::Image that is
    # sorted according to the options provided. Will raise any error that
    # occurs.
    def self.smart(input, o = {})
      startTime = Time.now
      defOptions = {
        reverse: false,
        vertical: false,
        diagonal: false,
        smooth: false,
        method: 'sum-rgb',
        verbose: false,
        absolute: false,
        threshold: 20,
        trusted: false,
        middle: false
      }
      defRules = {
        reverse: :anything,
        vertical: [false, true],
        diagonal: [false, true],
        smooth: [false, true],
        method: Pxlsrt::Colors::METHODS,
        verbose: [false, true],
        absolute: [false, true],
        threshold: [{ class: [Float, Integer] }],
        trusted: [false, true],
        middle: :anything
      }
      @options = defOptions.merge(o)
      if o.empty? || (options[:trusted] == true) || ((options[:trusted] == false) && !o.empty? && (checkOptions(options, defRules) != false))
        verbose('Options are all good.')
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
        elsif (input.class != String) && (input.class != ChunkyPNG::Image)
          error('Input is not a filename or ChunkyPNG::Image')
          raise 'Invalid input (must be filename or ChunkyPNG::Image)'
        end
        verbose('Smart mode.')
        png = Pxlsrt::Image.new(input)
        if !options[:vertical] && !options[:diagonal]
          verbose('Retrieving rows')
          lines = png.horizontalLines
        elsif options[:vertical] && !options[:diagonal]
          verbose('Retrieving columns')
          lines = png.verticalLines
        elsif !options[:vertical] && options[:diagonal]
          verbose('Retrieving diagonals')
          lines = png.diagonalLines
        elsif options[:vertical] && options[:diagonal]
          verbose('Retrieving diagonals')
          lines = png.rDiagonalLines
        end
        verbose('Retrieving edges')
        png.getSobels
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
          divisions = []
          division = []
          if line.length > 1
            (0...line.length).each do |pixel|
              if !options[:vertical] && !options[:diagonal]
                xy = png.horizontalXY(k, pixel)
              elsif options[:vertical] && !options[:diagonal]
                xy = png.verticalXY(k, pixel)
              elsif !options[:vertical] && options[:diagonal]
                xy = png.diagonalXY(k, pixel)
              elsif options[:vertical] && options[:diagonal]
                xy = png.rDiagonalXY(k, pixel)
              end
              pxlSobel = png.getSobelAndColor(xy['x'], xy['y'])
              if division.empty? || ((options[:absolute] ? pxlSobel['sobel'] : pxlSobel['sobel'] - division.last['sobel']) <= options[:threshold])
                division.push(pxlSobel)
              else
                divisions.push(division)
                division = [pxlSobel]
              end
              if pixel == line.length - 1
                divisions.push(division)
                division = []
              end
            end
          end
          newLine = []
          divisions.each do |band|
            newLine.concat(
              handlePixelSort(
                band.map { |sobelAndColor| sobelAndColor['color'] },
                options
              )
            )
          end
          if !options[:diagonal]
            png.replaceHorizontal(k, newLine) unless options[:vertical]
            png.replaceVertical(k, newLine) if options[:vertical]
          else
            png.replaceDiagonal(k, newLine) unless options[:vertical]
            png.replaceRDiagonal(k, newLine) if options[:vertical]
          end
          prr += 1
          progress('Dividing and pixel sorting lines', prr, len)
        end
        endTime = Time.now
        timeElapsed = endTime - startTime
        if timeElapsed < 60
          verbose("Took #{timeElapsed.round(4)} second#{timeElapsed.round(4) != 1.0 ? 's' : ''}.")
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
  end
end
