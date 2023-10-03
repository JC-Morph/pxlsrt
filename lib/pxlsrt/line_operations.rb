# frozen_string_literal: true

module Pxlsrt
  module LineOperations
    private

    def retrieve_lines
      lines = diagonal ? [:diagonals] : [:rows]
      if vertical
        lines = diagonal ? [:diagonals, true] : [:columns]
      end
      verbose "Retrieving #{lines.first}"
      png.send(*lines)
    end

    def replace_lines(idx, new_line)
      lines = diagonal ? [:diagonal] : [:row]
      if vertical
        lines = diagonal ? [:diagonal, true] : [:column]
      end
      lines.insert(1, idx, new_line)
      png.send("replace_#{lines[0]}!", *lines[1..])
    end

    def iterator
      diagonal ? lines.keys : (0...lines.size)
    end

    def diagonal
      @diagonal ||= options[:diagonal]
    end

    def vertical
      @vertical ||= options[:vertical]
    end

    def lines
      @lines ||= retrieve_lines
    end

    def total
      @total ||= iterator.to_a.size
    end
  end
end
