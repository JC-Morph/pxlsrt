require 'pxlsrt/colors'
require 'pxlsrt/lines'

module Pxlsrt
  # Methods not having to do with image or color manipulation.
  module Helpers
    # Determines if a value has content.
    def contented(value)
      !value.nil?
    end

    # Determines if a string can be a float or integer.
    def isNumeric?(str)
      true if Float(str)
    rescue
      false
    end

    # Checks if supplied options follow the rules.
    def checkOptions(options, rules)
      match = true
      options.each_key do |o|
        o_match = false
        if rules[o].class == Array
          if rules[o].include?(options[o])
            o_match = true
          else
            (0...rules[o].length).each do |r|
              if rules[o][r].class == Hash
                rules[o][r][:class].each do |n|
                  if n == options[o].class
                    o_match = match
                    break
                  end
                end
              end
              break if o_match == true
            end
          end
        elsif rules[o] == :anything
          o_match = true
        end
        match = (match && o_match)
        break if match == false
      end
      match
    end

    # Pixel sorting helper to eliminate repetition.
    def handlePixelSort(band, o)
      if ((o[:reverse].class == String) && (o[:reverse].casecmp('reverse').zero? || (o[:reverse] == ''))) || (o[:reverse] == true)
        reverse = 1
      elsif (o[:reverse].class == String) && o[:reverse].casecmp('either').zero?
        reverse = -1
      else
        reverse = 0
      end
      if o[:smooth]
        u = band.group_by { |x| x }
        k = u.keys
      else
        k = band
      end
      sortedBand = Pxlsrt::Colors.pixelSort(
        k,
        o[:method],
        reverse
      )
      sortedBand = sortedBand.flat_map { |x| u[x] } if o[:smooth]
      Pxlsrt::Lines.handleMiddlate(sortedBand, o[:middle])
    end

    # Progress indication.
    def progress(what, amount, outof)
      progress = (amount.to_f * 100.0 / outof.to_f).to_i
      if progress == 100
        puts "\r#{green('pxlsrt')} #{what} (#{green("#{progress}%")})"
      else
        $stdout.write "\r#{yellow('pxlsrt')} #{what} (#{yellow("#{progress}%")})"
        $stdout.flush
      end
    end

    private

    def error(str)
      color = {error: :red, verbose: :cyan}[__callee__]
      puts "#{send(color, 'pxlsrt')} #{str}" if options[:verbose]
    end
    alias_method :verbose, :error

    def color_str(str)
      "\e[#{color_index[__callee__]}m#{str}\e[0m"
    end
    color_index.keys.each {|color| alias_method color, :color_str }

    def color_index
      {cyan: 36, green: 32, red: 31, yellow: 33}
    end
  end
end
