require 'pxlsrt/colors'
require 'pxlsrt/lines'

module Pxlsrt
  # Methods not having to do with image or color manipulation.
  module Helpers
    # Determines if a value has content.
    def contented(c)
      !c.nil?
    end

    # Used to output a red string to the terminal.
    def red(what)
      "\e[31m#{what}\e[0m"
    end

    # Used to output a cyan string to the terminal.
    def cyan(what)
      "\e[36m#{what}\e[0m"
    end

    # Used to output a yellow string to the terminal.
    def yellow(what)
      "\e[33m#{what}\e[0m"
    end

    # Determines if a string can be a float or integer.
    def isNumeric?(s)
      true if Float(s)
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

    # Prints an error message.
    def error(what)
      puts "#{red('pxlsrt')} #{what}"
    end

    # Prints something.
    def verbose(what)
      puts "#{cyan('pxlsrt')} #{what}"
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
  end
end
