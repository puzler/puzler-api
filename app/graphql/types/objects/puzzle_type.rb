module Types
  module Objects
    class PuzzleType < BaseObject
      description "A variant sudoku puzzle"

      field :author, UserType, null: false, description: "Puzzle creator"
      field :avg_difficulty, Float, null: true, description: "Average difficulty rating from players (1–4 scale)"
      field :avg_rating, Float, null: true, description: "Average star rating from players (1–5 scale)"
      field :box_layout, GraphQL::Types::JSON, null: true,
        description: "Custom box region definitions; null means standard 3×3 boxes"
      field :comments, [ CommentType ], null: false, description: "Top-level comments, newest first"
      field :constraints, [ ConstraintType ], null: false, description: "Logical constraints attached to this puzzle"
      field :cosmetics, [ CosmeticType ], null: false, description: "Visual decorations attached to this puzzle"
      field :description, String, null: true, description: "Optional description or story text"
      field :favorite_count, Integer, null: false, description: "Number of times this puzzle has been favorited"
      field :given_digits, GraphQL::Types::JSON, null: false,
        description: "Pre-filled clue digits keyed by cell coordinate (r0c0: 5)"
      field :grid, GridType, null: false, description: "Grid dimensions"
      field :id, ID, null: false, description: "Unique puzzle ID"
      field :is_favorited, Boolean, null: false,
        description: "Whether the current user has favorited this puzzle"
      field :my_rating, RatingType, null: true, description: "Current user's rating for this puzzle"
      field :patreon_campaign_id, String, null: true,
        description: "Linked Patreon campaign for future patron integration"
      field :patron_visibility, String, null: false,
        description: "Patron visibility level for future Patreon integration"
      field :published_at, GraphQL::Types::ISO8601DateTime, null: true,
        description: "When this puzzle was published"
      field :ruleset, GraphQL::Types::JSON, null: false,
        description: "Boolean variant flags (diagonals, knights_move, etc.)"
      field :solution, GraphQL::Types::JSON, null: true,
        description: "Full solution grid; only visible to the puzzle author"
      field :solution_hash, String, null: true,
        description: "SHA-256 of the canonical solution, used for client-side completion detection"
      field :solve_count, Integer, null: false, description: "Number of times this puzzle has been solved"
      field :status, String, null: false, description: "Puzzle status: draft, published, or featured"
      field :tags, [ TagType ], null: false, description: "Tags categorizing this puzzle"
      field :title, String, null: false, description: "Puzzle title"

      def grid
        { rows: object.grid_rows, cols: object.grid_cols }
      end

      def solution
        return object.solution if context[:current_user]&.id == object.author_id || context[:current_user]&.admin?

        nil
      end

      def my_rating
        return nil unless context[:current_user]

        object.ratings.find_by(user: context[:current_user])
      end

      def is_favorited
        return false unless context[:current_user]

        object.favorites.exists?(user: context[:current_user])
      end

      def comments
        object.comments.top_level.by_newest.includes(:user, :replies)
      end
    end
  end
end
