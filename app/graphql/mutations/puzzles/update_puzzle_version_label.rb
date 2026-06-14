module Mutations
  module Puzzles
    class UpdatePuzzleVersionLabel < Mutations::BaseMutation
      description "Rename a puzzle version (pass null to clear back to the v{n} default)"

      argument :id, ID, required: true, description: "ID of the version to rename"
      argument :label, String, required: false, description: "New name, or null to reset to default"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :version, Types::Objects::PuzzleVersionType, null: true, description: "The updated version"

      def resolve(id:, label: nil)
        require_auth!
        version = owned_version(id)
        raise GraphQL::ExecutionError, "Version not found" unless version

        if version.update(label: label.presence)
          { version:, errors: [] }
        else
          { version: nil, errors: version.errors.full_messages }
        end
      end

      private

      def owned_version(id)
        PuzzleVersion.joins(:puzzle).find_by(id:, puzzles: { author_id: current_user.id })
      end
    end
  end
end
