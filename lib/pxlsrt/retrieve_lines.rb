# frozen_string_literal: true

module Pxlsrt
  module RetrieveLines
    private

    def retrieve_lines
      lines = diagonal ? [:diagonals] : [:rows]
      if vertical
        lines = diagonal ? [:diagonals, true] : [:columns]
      end
      verbose "Retrieving #{lines.first}"
      png.send(*lines)
    end

    def diagonal
      options[__callee__]
    end
    alias vertical diagonal
  end
end
