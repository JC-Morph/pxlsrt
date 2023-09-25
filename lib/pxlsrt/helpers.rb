require 'pxlsrt/colors'
require 'pxlsrt/lines'

module Pxlsrt
  # Methods not having to do with image or color manipulation.
  module Helpers
    # Checks if supplied options follow the rules.
    def check_options
      match = true
      options.each do |opt, val|
        rule = opt_rules[opt]
        opt_match = false
        if rule.class == Array
          if rule.include?(val)
            opt_match = true
          else
            (0...rule.length).each do |r|
              if rule[r].class == Hash
                rule[r][:class].each do |n|
                  if n == val.class
                    opt_match = match
                    break
                  end
                end
              end
              break if opt_match == true
            end
          end
        elsif rule == :anything
          opt_match = true
        end
        match = (match && opt_match)
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
    def progress(what, amount, total)
      return unless options[:verbose]
      progress   = (amount.to_f * 100.0 / total).to_i
      format_hsh = {what: what, progress: progress}
      return puts format(prog_str(:green), format_hsh) if progress == 100
      $stdout.write format(prog_str(:yellow), format_hsh)
      $stdout.flush
    end

    def prog_str(color)
      "\r#{send(color, 'pxlsrt')} %{what} (#{send(color, "%{progress}%%")})"
    end

    module_function

    def options
      {verbose: true}
    end

    def error(str)
      return unless options[:verbose]
      color = {error: :red, verbose: :cyan}[__callee__]
      puts "#{send(color, 'pxlsrt')} #{str}"
    end
    alias_method :verbose, :error

    def color_index
      {cyan: 36, green: 32, red: 31, yellow: 33}
    end

    def color_str(str)
      "\e[#{color_index[__callee__]}m#{str}\e[0m"
    end
    color_index.keys.each {|color| alias_method color, :color_str }

    # Determines if a string can be a float or integer.
    def isNumeric?(str)
      true if Float(str)
    rescue
      false
    end

    private

    def opt_rules
      raise NotImplementedError
    end
  end
end
