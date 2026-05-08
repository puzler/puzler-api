module Mutations
  module Puzzles
    class PublishPuzzle < Mutations::BaseMutation
      description "Publish a draft puzzle, optionally attaching tags"

      argument :id, ID, required: true,
        description: "ID of the puzzle to publish"
      argument :tag_slugs, [ String ], required: false,
        description: "Tag slugs to attach to the puzzle before publishing"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true,
        description: "The newly published puzzle"

      def resolve(id:, tag_slugs: [])
        require_auth!
        puzzle = current_user.puzzles.find_by(id:)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle
        raise GraphQL::ExecutionError, "Solution required before publishing" if puzzle.solution.blank?

        puzzle.tags = tag_slugs.map { |slug| Tag.find_by(slug:) }.compact

        if puzzle.update(status: :published, published_at: Time.current)
          { puzzle:, errors: [] }
        else
          { puzzle: nil, errors: puzzle.errors.full_messages }
        end
      end
    end
  end
end
