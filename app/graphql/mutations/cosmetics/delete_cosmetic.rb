module Mutations
  module Cosmetics
    class DeleteCosmetic < Mutations::BaseMutation
      description "Delete a cosmetic from a puzzle"

      argument :id, ID, required: true,
        description: "ID of the cosmetic to delete"

      field :success, Boolean, null: false,
        description: "True when the cosmetic was successfully deleted"

      def resolve(id:)
        require_auth!
        cosmetic = ::Cosmetic.joins(:puzzle).where(puzzles: { author_id: current_user.id }).find_by(id:)
        raise GraphQL::ExecutionError, "Cosmetic not found" unless cosmetic

        cosmetic.destroy
        { success: true }
      end
    end
  end
end
