module Mutations
  module Puzzles
    # Build a short SudokuPad link from the editor's live puzzle definition. The
    # client sends its serialized Puzler definition (+ solution); the server
    # converts → compresses → shortens — no f-puzzles logic lives on the client.
    class ExportSudokupadLink < Mutations::BaseMutation
      description "Build a short SudokuPad link from a Puzler definition"

      MAX_DEFINITION_BYTES = 500_000
      RATE_LIMIT = 60
      RATE_WINDOW = 1.minute

      argument :definition, GraphQL::Types::JSON, required: true,
        description: "The serialized Puzler definition (play-safe; solution passed separately)"
      argument :include_solution, Boolean, required: false,
        description: "Embed the solution so SudokuPad can solve-check (defaults true)"
      argument :solution, GraphQL::Types::JSON, required: false,
        description: "Solution grid (cell key → digit); embedded only when include_solution is set"

      field :errors, [ String ], null: false, description: "Errors, if any"
      field :url, String, null: true, description: "The short SudokuPad URL, or null on failure"
      field :warnings, [ String ], null: false, description: "Notes for anything that couldn't be represented"

      def resolve(definition:, solution: nil, include_solution: true)
        # Open to guests too: exporting a link exposes nothing that isn't already
        # in the definition the client sent us.
        return { url: nil, warnings: [], errors: [ "Puzzle data is too large" ] } if definition.to_json.bytesize > MAX_DEFINITION_BYTES
        return { url: nil, warnings: [], errors: [ "Too many requests; try again shortly" ] } if rate_limited?

        result = Sudokupad::LinkBuilder.build(
          definition: definition, solution: solution, include_solution: include_solution,
          fallback_author: current_user&.display_name
        )
        return { url: nil, warnings: [], errors: [ "This puzzle can't be exported to SudokuPad (it needs a square grid with sudoku rules)." ] } unless result

        { url: result[:short_url], warnings: result[:warnings], errors: [] }
      end

      private

      def rate_limited?
        key = current_user ? "user:#{current_user.id}" : "ip:#{request_ip}"
        count = Rails.cache.increment("sudokupad_export:#{key}", 1, expires_in: RATE_WINDOW)
        count.present? && count > RATE_LIMIT
      end
    end
  end
end
