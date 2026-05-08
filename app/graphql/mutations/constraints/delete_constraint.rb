module Mutations
  module Constraints
    class DeleteConstraint < Mutations::BaseMutation
      description "Delete a constraint from a puzzle"

      argument :id, ID, required: true,
        description: "ID of the constraint to delete"

      field :success, Boolean, null: false,
        description: "True when the constraint was successfully deleted"

      def resolve(id:)
        require_auth!
        constraint = ::Constraint.joins(:puzzle).where(puzzles: { author_id: current_user.id }).find_by(id:)
        raise GraphQL::ExecutionError, "Constraint not found" unless constraint

        constraint.destroy
        { success: true }
      end
    end
  end
end
