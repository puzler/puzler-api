# frozen_string_literal: true

module FPuzzle
  class Converter
    def from_f_puzzle(base64_data)
      puzzle_data = FPuzzle::Base64.decode(base64_data)
      parse_f_puzzle(puzzle_data)
    end

    def to_f_puzzle(puzzle)
      f_puzzle_data = generate_f_puzzle(puzzle)
      FPuzzle::Base64.encode(f_puzzle_data)
    end

    private

    def generate_f_puzzle(puzzle)
      {
        author: puzzle.author,
        ruleset: puzzle.rules,
        title: puzzle.title,
        size: puzzle.size,
        **FPuzzle::Exporters::Grid.parse(puzzle),
        **FPuzzle::Exporters::Cosmetics.parse(puzzle),
        **FPuzzle::Exporters::Globals.parse(puzzle),
        **FPuzzle::Exporters::Locals.parse(puzzle)
      }
    end

    def parse_f_puzzle(puzzle_data)
      @size = puzzle_data[:size]
      grid_data = parse_puzzle_grid(puzzle_data[:grid])
      Puzzle.new(
        author: puzzle_data[:author],
        rules: puzzle_data[:ruleset],
        title: puzzle_data[:title],
        size: @size,
        visibility: :unlisted,
        cells: grid_data[:cells],
        global_constraints: FPuzzle::Parsers::Globals.parse(puzzle_data),
        local_constraints: FPuzzle::Parsers::Locals.parse(puzzle_data),
        cosmetics: FPuzzle::Parsers::Cosmetics.parse(
          puzzle_data,
          cell_background_colors: grid_data[:colors]
        )
      )
    end

    def dimensions_for_size(size)
      factors = []
      mid = Math.sqrt(size).floor

      (1..mid).each do |i|
        next unless (size % i).zero?

        factors.push i
        flip = size / i
        factors.push flip unless flip == i
      end
      factors.sort!

      {
        width: factors[((factors.length - 1) / 2.0).ceil],
        height: factors[((factors.length - 1) / 2.0).floor]
      }
    end

    def parse_puzzle_grid(grid)
      grid.each_with_object({ cells: [], colors: [] }) do |row_cells, data|
        data[:cells] << []
        row_cells.each_with_index do |cell_data, col|
          cell, color = parse_cell_data(cell_data, row: data[:cells].length - 1, col:)

          data[:cells].last << cell
          data[:colors] << color if color
        end
      end
    end

    def parse_cell_data(cell_data, row:, col:)
      @dimensions ||= dimensions_for_size(@size)
      @regions_per_row ||= @size / @dimensions[:width]

      default_region = ((row / @dimensions[:height]).floor * @regions_per_row) + (col / @dimensions[:width]).floor
      cell = { region: cell_data[:region] || default_region }
      cell.merge!(given: true, digit: cell_data[:value]) if cell_data[:given]
      return cell unless cell_data[:c] || cell_data[:c_array]

      [
        cell,
        { cell: { row:, column: col }, colors: parse_cell_colors(cell_data) }
      ]
    end

    def parse_cell_colors(cell_data)
      colors = cell_data[:c_array]&.map { |c| ColorHelper.rgba_from_string(c) }
      colors ||= [ColorHelper.rgba_from_string(cell_data[:c])]

      colors
    end
  end
end
