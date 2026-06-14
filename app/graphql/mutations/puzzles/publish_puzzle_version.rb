module Mutations
  module Puzzles
    class PublishPuzzleVersion < Mutations::BaseMutation
      description "Publish a specific version so it becomes the live one solvers see"

      argument :puzzle_id, ID, required: true, description: "ID of the puzzle"
      argument :tag_slugs, [ String ], required: false, description: "Tag slugs to attach before publishing"
      argument :version_id, ID, required: true, description: "Version to publish"
      argument :visibility, String, required: false, description: "Optionally set the access mode at the same time"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true, description: "The published puzzle"

      def resolve(puzzle_id:, version_id:, visibility: nil, tag_slugs: nil)
        require_auth!
        puzzle = current_user.puzzles.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        version = puzzle.versions.find_by(id: version_id)
        raise GraphQL::ExecutionError, "Version not found" unless version
        return { puzzle: nil, errors: [ "Solution required before publishing" ] } if version.solution.blank?
        if visibility && SetPuzzleVisibility::SELECTABLE.exclude?(visibility)
          return { puzzle: nil, errors: [ "Unsupported visibility: #{visibility}" ] }
        end

        puzzle.tags = tag_slugs.filter_map { |slug| Tag.find_by(slug:) } if tag_slugs

        attrs = {
          published_version: version,
          status: :published,
          constraint_types: version.constraint_types,
          published_at: puzzle.published_at || Time.current
        }
        attrs[:visibility] = visibility if visibility

        if puzzle.update(attrs)
          { puzzle:, errors: [] }
        else
          { puzzle: nil, errors: puzzle.errors.full_messages }
        end
      end
    end
  end
end
