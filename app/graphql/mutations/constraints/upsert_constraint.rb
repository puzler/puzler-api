module Mutations
  module Constraints
    class UpsertConstraint < Mutations::BaseMutation
      description "Create or update a constraint on a puzzle"

      argument :attrs, Types::InputObjects::ConstraintAttrsInput, required: true,
        description: "Constraint attributes to create or update"
      argument :id, ID, required: false,
        description: "ID of the constraint to update; omit to create a new one"
      argument :puzzle_id, ID, required: true,
        description: "ID of the puzzle this constraint belongs to"

      field :constraint, Types::Objects::ConstraintType, null: true,
        description: "The created or updated constraint"
      field :errors, [ String ], null: false,
        description: "Validation errors, if any"

      def resolve(puzzle_id:, attrs:, id: nil)
        require_auth!
        puzzle = current_user.puzzles.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        constraint = id ? puzzle.constraints.find_by(id:) : puzzle.constraints.build
        raise GraphQL::ExecutionError, "Constraint not found" if id && constraint.nil?

        update_attrs = { constraint_type: attrs.constraint_type, data: attrs.data }
          .tap { |h| h[:display_order] = attrs.display_order if attrs.display_order }

        if constraint.update(update_attrs)
          { constraint:, errors: [] }
        else
          { constraint: nil, errors: constraint.errors.full_messages }
        end
      end
    end
  end
end
