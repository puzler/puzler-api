module Mutations
  module Cosmetics
    class UpsertCosmetic < Mutations::BaseMutation
      description "Create or update a cosmetic on a puzzle"

      argument :attrs, Types::InputObjects::CosmeticAttrsInput, required: true,
        description: "Cosmetic attributes to create or update"
      argument :id, ID, required: false,
        description: "ID of the cosmetic to update; omit to create a new one"
      argument :puzzle_id, ID, required: true,
        description: "ID of the puzzle this cosmetic belongs to"

      field :cosmetic, Types::Objects::CosmeticType, null: true,
        description: "The created or updated cosmetic"
      field :errors, [ String ], null: false,
        description: "Validation errors, if any"

      def resolve(puzzle_id:, attrs:, id: nil)
        require_auth!
        puzzle = current_user.puzzles.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        cosmetic = id ? puzzle.cosmetics.find_by(id:) : puzzle.cosmetics.build
        raise GraphQL::ExecutionError, "Cosmetic not found" if id && cosmetic.nil?

        update_attrs = { cosmetic_type: attrs.cosmetic_type, position: attrs.position,
                         style: attrs.style, data: attrs.data }
          .tap { |h| h[:display_order] = attrs.display_order if attrs.display_order }

        if cosmetic.update(update_attrs)
          { cosmetic:, errors: [] }
        else
          { cosmetic: nil, errors: cosmetic.errors.full_messages }
        end
      end
    end
  end
end
