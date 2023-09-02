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
      lines = diagonal ? :Diagonal : :_row!
      if vertical
        lines = diagonal ? :RDiagonal : :_column!
      end
      png.send("replace#{lines}", idx, new_line)
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
