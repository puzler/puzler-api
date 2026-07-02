module Mutations
  module Folders
    class MovePuzzleToFolder < Mutations::BaseMutation
      description "File a puzzle into a folder, or pass a null folder to unfile it"

      argument :folder_id, ID, required: false, description: "Target folder, or null to unfile"
      argument :puzzle_id, ID, required: true, description: "Puzzle to move"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true, description: "The moved puzzle"

      def resolve(puzzle_id:, folder_id: nil)
        puzzle = require_owned!(:puzzles, "Puzzle", id: puzzle_id)

        if folder_id.present? && !current_user.folders.exists?(id: folder_id)
          raise GraphQL::ExecutionError, "Folder not found"
        end

        puzzle.update(folder_id:)
        { puzzle:, errors: [] }
      end
    end
  end
end
