require 'oily_png'
require 'pxlsrt/colors'
require 'pxlsrt/sort_class'
require 'pxlsrt/spiral'

module Pxlsrt
  # Plant seeds, have them spiral out and sort.
  class Seed < SortClass
    class << self
      # The main attraction of the Seed class. Returns a ChunkyPNG::Image that
      # is sorted according to the options provided. Will raise any error that
      # occurs.
      def call(input, o = {})
        startTime = Time.now
        @options = opt_defaults.merge(o)
        if o.empty? || (options[:trusted] == true) || ((options[:trusted] == false) && !o.empty? && (checkOptions(options, opt_rules) != false))
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
              raise "File doesn't exit"
            end
          elsif (input.class != String) && (input.class != ChunkyPNG::Image)
            error('Input is not a filename or ChunkyPNG::Image')
            raise 'Invalid input (must be filename or ChunkyPNG::Image)'
          end
          verbose('Seed mode.')
          verbose('Creating Pxlsrt::Image object')
          png = Pxlsrt::Image.new(input)
          traversed = [false] * (png.getWidth * png.getHeight)
          count = 0
          seeds = []
          if options[:random] != false
            progress('Planting seeds', 0, options[:random])
            (0...options[:random]).each do |s|
              x = (0...png.getWidth).to_a.sample
              y = (0...png.getHeight).to_a.sample
              seeds.push(spiral: Pxlsrt::Spiral.new(x, y),
                         pixels: [png[x, y]],
                         xy: [{ x: x, y: y }],
                         placed: true,
                         retired: false,
                         anchor: {
                           x: x,
                           y: y
                         })
              progress('Planting seeds', s + 1, options[:random])
            end
          else
            progress('Planting seeds', 0, png.getWidth * png.getHeight)
            kernel = [[-1, -1, -1], [-1, 9, -1], [-1, -1, -1]]
            i = (png.getWidth + png.getHeight - 2) * 2
            (1...(png.getHeight - 1)).each do |y|
              (1...(png.getWidth - 1)).each do |x|
                sum = 0
                (-1..1).each do |ky|
                  (-1..1).each do |kx|
                    sum += kernel[ky + 1][kx + 1] * ChunkyPNG::Color.r(png[x + kx, y + ky])
                  end
                end
                if sum < options[:threshold]
                  seeds.push(spiral: Pxlsrt::Spiral.new(x, y),
                             pixels: [png[x, y]],
                             xy: [{ x: x, y: y }],
                             placed: true,
                             retired: false,
                             anchor: {
                               x: x,
                               y: y
                             })
                end
                i += 1
                progress('Planting seeds', i, png.getWidth * png.getHeight)
              end
            end
            if options[:distance] != false
              progress('Removing seed clusters', 0, seeds.length)
              results = []
              i = 0
              seeds.each do |current|
                add = true
                results.each do |other|
                  d = Math.sqrt((current[:anchor][:x] - other[:anchor][:x])**2 + (current[:anchor][:y] - other[:anchor][:y])**2)
                  add = false if d > 0 && d < options[:distance]
                end
                results.push(current) if add
                i += 1
                progress('Removing seed clusters', i, seeds.length)
              end
              seeds = results
            end
          end
          (0...seeds.length).each do |r|
            traversed[seeds[r][:anchor][:x] + seeds[r][:anchor][:y] * png.getWidth] = r
            count += 1
          end
          verbose("Planted #{seeds.length} seeds")
          step = 0
          progress('Watch them grow!', count, traversed.length)
          while count < traversed.length && !seeds.empty?
            r = 0
            seeds.each do |seed|
              unless seed[:retired]
                n = seed[:spiral].next
                if (n[:x] >= 0) && (n[:y] >= 0) && n[:x] < png.getWidth && n[:y] < png.getHeight && !traversed[n[:x] + n[:y] * png.getWidth]
                  seed[:pixels].push(png[n[:x], n[:y]])
                  traversed[n[:x] + n[:y] * png.getWidth] = r
                  seed[:xy].push(n)
                  seed[:placed] = true
                  count += 1
                elsif seed[:placed] == true
                  seed[:placed] = {
                    count: 1,
                    direction: seed[:spiral].direction,
                    cycle: seed[:spiral].cycles
                  }
                  case seed[:placed][:direction]
                  when 'up', 'down'
                    seed[:placed][:value] = seed[:spiral].pos[:y]
                    seed[:placed][:valueS] = :y
                  when 'left', 'right'
                    seed[:placed][:value] = seed[:spiral].pos[:x]
                    seed[:placed][:valueS] = :x
                  end
                else
                  seed[:placed][:count] += 1
                  if (seed[:spiral].cycles != seed[:placed][:cycle]) && (seed[:placed][:direction] == seed[:spiral].direction) && (seed[:placed][:value] == seed[:spiral].pos[seed[:placed][:valueS]])
                    seed[:retired] = true
                  end
                end
              end
              r += 1
            end
            step += 1
            progress('Watch them grow!', count, traversed.length)
          end
          progress('Sort seeds and place pixels', 0, seeds.length)
          r = 0
          seeds.each do |seed|
            band = handlePixelSort(seed[:pixels], options)
            i = 0
            seed[:xy].each do |k|
              png[k[:x], k[:y]] = band[i]
              i += 1
            end
            r += 1
            progress('Sort seeds and place pixels', r, seeds.length)
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

      private

      def opt_defaults
        {
          random:    false,
          distance:  100,
          threshold: 0.1
        }.merge common_defaults
      end

      def opt_rules
        {
          random:    [false, {class: [Integer]}],
          distance:  [false, {class: [Integer]}],
          threshold: [{class: [Float, Integer]}]
        }.merge common_rules
      end
    end
  end
end
