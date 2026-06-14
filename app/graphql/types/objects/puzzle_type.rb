module Types
  module Objects
    class PuzzleType < BaseObject
      description "A variant sudoku puzzle"

      field :author, UserType, null: false, description: "Puzzle creator"
      field :avg_difficulty, Float, null: true, description: "Average difficulty rating from players (1–4 scale)"
      field :avg_rating, Float, null: true, description: "Average star rating from players (1–5 scale)"
      field :box_layout, GraphQL::Types::JSON, null: true,
        description: "Custom box region definitions; null means standard 3×3 boxes"
      field :collection_ids, [ ID ], null: false,
        description: "IDs of the author's collections containing this puzzle; only visible to the author"
      field :comments, [ CommentType ], null: false, description: "Top-level comments, newest first"
      field :constraint_types, [ String ], null: false,
        description: "Constraint-type tags from the published version, for archive filtering"
      field :constraints, [ ConstraintType ], null: false, description: "Logical constraints attached to this puzzle"
      field :cosmetics, [ CosmeticType ], null: false, description: "Visual decorations attached to this puzzle"
      field :description, String, null: true, description: "Optional description or story text"
      field :favorite_count, Integer, null: false, description: "Number of times this puzzle has been favorited"
      field :featured, Boolean, null: false, description: "Whether an admin has featured this puzzle"
      field :folder, FolderType, null: true,
        description: "Folder this puzzle is filed in; only visible to the author"
      field :given_digits, GraphQL::Types::JSON, null: false,
        description: "Pre-filled clue digits keyed by cell coordinate (r0c0: 5)"
      field :granted_users, [ UserType ], null: false,
        description: "Users explicitly granted access to this private puzzle; only visible to the author"
      field :grid, GridType, null: false, description: "Grid dimensions"
      field :id, ID, null: false, description: "Unique puzzle ID"
      field :is_favorited, Boolean, null: false,
        description: "Whether the current user has favorited this puzzle"
      field :my_rating, RatingType, null: true, description: "Current user's rating for this puzzle"
      field :patreon_campaign_id, String, null: true,
        description: "Linked Patreon campaign for future patron integration"
      field :published_at, GraphQL::Types::ISO8601DateTime, null: true,
        description: "When this puzzle was published"
      field :published_version, PuzzleVersionType, null: true,
        description: "The version currently published to solvers"
      field :ruleset, GraphQL::Types::JSON, null: false,
        description: "Boolean variant flags (diagonals, knights_move, etc.)"
      field :share_token, String, null: true,
        description: "Unguessable share/solve URL key; only visible to the author"
      field :solution, GraphQL::Types::JSON, null: true,
        description: "Full solution grid; only visible to the puzzle author"
      field :solution_hash, String, null: true,
        description: "SHA-256 of the canonical solution, used for client-side completion detection"
      field :solve_count, Integer, null: false, description: "Number of times this puzzle has been solved"
      field :status, String, null: false, description: "Lifecycle status: draft or published"
      field :tags, [ TagType ], null: false, description: "Tags categorizing this puzzle"
      field :title, String, null: false, description: "Puzzle title"
      field :versions, [ PuzzleVersionType ], null: false,
        description: "All saved versions, oldest first; only visible to the author"
      field :visibility, String, null: false,
        description: "Access mode: private, unlisted, public, patrons_only, or subscribers_only"

      def grid
        { rows: object.grid_rows, cols: object.grid_cols }
      end

      def solution
        return object.solution if author_or_admin?

        nil
      end

      def share_token
        return object.share_token if author_or_admin?

        nil
      end

      def versions
        return PuzzleVersion.none unless author_or_admin?

        object.versions
      end

      def granted_users
        return User.none unless author_or_admin?

        object.granted_users
      end

      def folder
        object.folder if author_or_admin?
      end

      def collection_ids
        return [] unless author_or_admin?

        object.collection_ids.map(&:to_s)
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

      private

      def author_or_admin?
        context[:current_user]&.id == object.author_id || context[:current_user]&.admin?
      end
    end
  end
end
