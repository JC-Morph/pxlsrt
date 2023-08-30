require 'oily_png'
require 'pxlsrt/colors'
require 'pxlsrt/sort_class'

module Pxlsrt
  # Brute sorting creates bands for sorting using a range to determine the
  # bandwidths, as opposed to smart sorting which uses edge-finding to create
  # bands.
  class Brute < SortClass
    # The main attraction of the Brute class. Returns a ChunkyPNG::Image that
    # is sorted according to the options provided. Will raise any error that
    # occurs.
    def self.call(input, o = {})
      startTime = Time.now
      defOptions = {
        reverse: false,
        vertical: false,
        diagonal: false,
        smooth: false,
        method: 'sum-rgb',
        verbose: false,
        min: Float::INFINITY,
        max: Float::INFINITY,
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
        min: [Float::INFINITY, { class: [Integer] }],
        max: [Float::INFINITY, { class: [Integer] }],
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
        verbose('Brute mode.')
        verbose('Creating Pxlsrt::Image object')
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
          divisions = Pxlsrt::Lines.randomSlices(line.length, options[:min], options[:max])
          newLine = []
          divisions.each do |division|
            band = line[division[0]..division[1]]
            newLine.concat(handlePixelSort(band, options))
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
  end
end
