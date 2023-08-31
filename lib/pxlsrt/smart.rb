require 'pxlsrt/sort_class'

module Pxlsrt
  # Smart sorting uses sorted-finding algorithms to create bands to sort,
  # as opposed to brute sorting which doesn't care for the content or
  # sorteds, just a specified range to create bands.
  class Smart < SortClass
    class << self
      # The main attraction of the Smart class. Returns a ChunkyPNG::Image that
      # is sorted according to the options provided. Will raise any error that
      # occurs.
      def call(input, o = {})
        @options = opt_defaults.merge(o)
        if o.empty? || (options[:trusted] == true) || ((options[:trusted] == false) && !o.empty? && (check_options != false))
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
          elsif input.class != ChunkyPNG::Image
            error('Input is not a filename or ChunkyPNG::Image')
            raise 'Invalid input (must be filename or ChunkyPNG::Image)'
          end
          verbose('Smart mode.')
          png = Pxlsrt::Image.new(input)
          if !options[:vertical] && !options[:diagonal]
            verbose('Retrieving rows')
            lines = png.rows
          elsif options[:vertical] && !options[:diagonal]
            verbose('Retrieving columns')
            lines = png.columns
          elsif !options[:vertical] && options[:diagonal]
            verbose('Retrieving diagonals')
            lines = png.diagonals
          elsif options[:vertical] && options[:diagonal]
            verbose('Retrieving diagonals')
            lines = png.diagonals(reverse: true)
          end
          verbose('Retrieving edges')
          png.sobels
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
                  xy = png.horizontal_coords(k, pixel)
                elsif options[:vertical] && !options[:diagonal]
                  xy = png.vertical_coords(k, pixel)
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
              png.replace_rows(k, newLine) unless options[:vertical]
              png.replace_columns(k, newLine) if options[:vertical]
            else
              png.replaceDiagonal(k, newLine) unless options[:vertical]
              png.replaceRDiagonal(k, newLine) if options[:vertical]
            end
            prr += 1
            progress('Dividing and pixel sorting lines', prr, len)
          end
          verbose('Returning ChunkyPNG::Image...')
          return png.modified
        else
          error('Options specified do not follow the correct format.')
          raise 'Bad options'
        end
      end

      private

      def opt_defaults
        {
          vertical:  false,
          diagonal:  false,
          absolute:  false,
          threshold: 20
        }.merge common_defaults
      end

      def opt_rules
        {
          vertical:  bool_rule,
          diagonal:  bool_rule,
          absolute:  bool_rule,
          threshold: [{class: [Float, Integer]}]
        }.merge common_rules
      end
    end
  end
end
