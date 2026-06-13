module Mutations
  module Social
    class ToggleFavorite < Mutations::BaseMutation
      description "Add or remove a puzzle from the current user's favorites"

      argument :puzzle_id, ID, required: true,
        description: "ID of the puzzle to favorite or unfavorite"

      field :favorite_count, Integer, null: false,
        description: "Updated favorite count after the toggle"
      field :is_favorited, Boolean, null: false,
        description: "True if the puzzle is now favorited by the current user"

      def resolve(puzzle_id:)
        require_auth!
        puzzle = Puzzle.publicly_visible.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        favorite = current_user.favorites.find_by(puzzle:)
        if favorite
          favorite.destroy
          puzzle.decrement!(:favorite_count)
          { is_favorited: false, favorite_count: puzzle.reload.favorite_count }
        else
          current_user.favorites.create!(puzzle:)
          puzzle.increment!(:favorite_count)
          { is_favorited: true, favorite_count: puzzle.reload.favorite_count }
        end
      end
    end
  end
end
