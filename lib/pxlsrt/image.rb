require 'forwardable'
require 'oily_png'
require 'pxlsrt/lines'

module Pxlsrt
  # Image class for handling ChunkyPNG images.
  class Image
    extend Forwardable
    def_delegators :@modified, :[], :[]=, :replace_column!, :replace_row!
    attr_reader :width, :height, :modified

    def initialize(png)
      @width    = png.width
      @height   = png.height
      @modified = ChunkyPNG::Image.from_canvas(png)
      @grey     = Array.new(height) do |y|
        Array.new(width) do |x|
          ChunkyPNG::Color.grayscale_teint(png[x, y])
        end
      end
    end

    # Retrieve a multidimensional array consisting of the horizontal lines (row)
    # of the image.
    def rows
      slice_image(height, :row)
    end

    # Retrieve the x and y coordinates of a pixel based on the multidimensional
    # array created using the #rows method.
    def horizontal_coords(horizontal, index)
      {
        x: index.to_i,
        y: horizontal.to_i
      }
    end

    # Retrieve a multidimensional array consisting of the vertical lines of the
    # image.
    def columns
      slice_image(width, :column)
    end

    # Retrieve the x and y coordinates of a pixel based on the multidimensional
    # array created using the #columns method.
    def vertical_coords(vertical, index)
      {
        x: vertical.to_i,
        y: index.to_i
      }
    end

    # Retrieve a hash consisting of the diagonal lines of the image.
    # (Top left -> Bottom right), reverse option for (Bottom left -> Top right).
    def diagonals(reverse = false)
      flat_rows = reverse ? rows.reverse.flatten(1).reverse : rows.flatten(1)
      Pxlsrt::Lines.getDiagonals(flat_rows, width, height)
    end

    # Replace a diagonal line (top left to bottom right) of the image.
    def replaceDiagonal(diag, arr)
      (0...arr.length).each do |idx|
        coords = diagonal_coords(diag, idx)
        self[coords[:x], coords[:y]] = arr[idx]
      end
    end

    # Replace a diagonal line (bottom left to top right) of the image.
    def replaceRDiagonal(diag, arr)
      (0...arr.length).each do |idx|
        coords = rDiagonal_coords(diag, idx)
        self[coords[:x], coords[:y]] = arr[idx]
      end
    end

    # Retrieve the x and y coordinates of a pixel based on the hash created
    # using the #diagonals method.
    def diagonal_coords(diag, idx)
      diag = diag.to_i
      {
        x: diag < 0 ? idx : (diag + idx),
        y: diag < 0 ? (diag.abs + idx) : idx
      }
    end

    # Retrieve the x and y coordinates of a pixel based on the hash created
    # using the #diagonals method.
    def rDiagonal_coords(d, i)
      coords = diagonal_coords(d, i)
      coords.merge(x: width - coords[:x] - 1)
    end

    # Retrieve Sobel value for a given pixel.
    def compute_sobel(x, y)
      if !defined?(@sobels)
        @sobel_x ||= [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]]
        @sobel_y ||= [[-1, -2, -1], [0, 0, 0], [1, 2, 1]]
        return 0 if x.zero? || (x == (@width - 1)) || y.zero? || (y == (@height - 1))
        t1 = @grey[y - 1][x - 1]
        t2 = @grey[y - 1][x]
        t3 = @grey[y - 1][x + 1]
        t4 = @grey[y][x - 1]
        t5 = @grey[y][x]
        t6 = @grey[y][x + 1]
        t7 = @grey[y + 1][x - 1]
        t8 = @grey[y + 1][x]
        t9 = @grey[y + 1][x + 1]
        pixel_x = (@sobel_x[0][0] * t1) + (@sobel_x[0][1] * t2) + (@sobel_x[0][2] * t3) + (@sobel_x[1][0] * t4) + (@sobel_x[1][1] * t5) + (@sobel_x[1][2] * t6) + (@sobel_x[2][0] * t7) + (@sobel_x[2][1] * t8) + (@sobel_x[2][2] * t9)
        pixel_y = (@sobel_y[0][0] * t1) + (@sobel_y[0][1] * t2) + (@sobel_y[0][2] * t3) + (@sobel_y[1][0] * t4) + (@sobel_y[1][1] * t5) + (@sobel_y[1][2] * t6) + (@sobel_y[2][0] * t7) + (@sobel_y[2][1] * t8) + (@sobel_y[2][2] * t9)
        Math.sqrt(pixel_x * pixel_x + pixel_y * pixel_y).ceil
      else
        @sobels[y * @width + x]
      end
    end

    # Retrieve the Sobel values for every pixel and set it as @sobel.
    def sobels
      @sobels ||= (0...(width * height)).each.with_object([]) do |xy, arr|
        sobel = compute_sobel(xy % width, (xy / width).floor)
        arr << sobel
      end
    end

    # Retrieve the Sobel value and color of a pixel.
    def sobel_and_color(x, y)
      {
        'sobel' => compute_sobel(x, y),
        'color' => self[x, y]
      }
    end

    def i(i)
      x = i % width
      y = (i / width).floor
      self[x, y]
    end

    def i=(i, color)
      x = i % width
      y = (i / width).floor
      self[x, y] = color
    end

    private

    def slice_image(dimension, direction)
      (0...dimension).each_with_object([]) do |line, arr|
        arr << modified.send(direction, line)
      end
    end
  end
end
