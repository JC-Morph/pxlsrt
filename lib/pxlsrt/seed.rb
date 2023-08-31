require 'pxlsrt/sort_class'
require 'pxlsrt/spiral'

module Pxlsrt
  # Plant seeds, have them spiral out and sort.
  class Seed < SortClass
    class << self
      # The main attraction of the Seed class. Returns a ChunkyPNG::Image that
      # is sorted according to the options provided. Will raise any error that
      # occurs.
      def call
        verbose 'Seed mode.'
        traversed = [false] * (png.width * png.height)
        count = 0
        seeds = []
        if options[:random] != false
          progress('Planting seeds', 0, options[:random])
          (0...options[:random]).each do |s|
            x = (0...png.width).to_a.sample
            y = (0...png.height).to_a.sample
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
          progress('Planting seeds', 0, png.width * png.height)
          kernel = [[-1, -1, -1], [-1, 9, -1], [-1, -1, -1]]
          i = (png.width + png.height - 2) * 2
          (1...(png.height - 1)).each do |y|
            (1...(png.width - 1)).each do |x|
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
              progress('Planting seeds', i, png.width * png.height)
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
          traversed[seeds[r][:anchor][:x] + seeds[r][:anchor][:y] * png.width] = r
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
              if (n[:x] >= 0) && (n[:y] >= 0) && n[:x] < png.width && n[:y] < png.height && !traversed[n[:x] + n[:y] * png.width]
                seed[:pixels].push(png[n[:x], n[:y]])
                traversed[n[:x] + n[:y] * png.width] = r
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
        verbose('Returning ChunkyPNG::Image...')
        png.modified
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
