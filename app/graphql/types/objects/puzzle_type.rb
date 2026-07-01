module Types
  module Objects
    class PuzzleType < BaseObject
      description "A variant sudoku puzzle"

      field :author, UserType, null: false, description: "Puzzle creator (the owning account)"
      field :author_difficulty, Integer, null: true,
        description: "Difficulty the setter chose, 1 (gentlest) to 5 (hardest); null if unset"
      field :author_name, String, null: true,
        description: "Free-form author credit from the published puzzle's metadata; null when left blank, " \
          "in which case attribution falls back to the author's display name"
      field :avg_difficulty, Float, null: true,
        description: "Community difficulty average from solver votes (1–5 scale)"
      field :avg_rating, Float, null: true, description: "Average star rating from players (1–5 scale)"
      field :box_layout, GraphQL::Types::JSON, null: true,
        description: "Custom box region definitions; null means standard 3×3 boxes"
      field :collection_ids, [ ID ], null: false,
        description: "IDs of the author's collections containing this puzzle; only visible to the author"
      field :comments, [ CommentType ], null: false, description: "Top-level comments, newest first"
      field :comments_require_solve_effective, Boolean, null: false, method: :comments_require_solve?,
        description: "Whether comments are gated to confirmed solvers (the per-puzzle override, or the author's default)"
      field :comments_require_solve_override, Boolean, null: true,
        description: "Per-puzzle comment-gate override; null inherits the author default (author only)"
      field :constraint_types, [ String ], null: false,
        description: "Constraint-type tags from the published version, for archive filtering"
      field :constraints, [ ConstraintType ], null: false, description: "Logical constraints attached to this puzzle"
      field :cosmetics, [ CosmeticType ], null: false, description: "Visual decorations attached to this puzzle"
      field :description, String, null: true, description: "Optional description or story text"
      field :effective_difficulty, Float, null: true,
        description: "Difficulty shown in the archive: the community average once there are enough votes, " \
          "otherwise the setter's value; null until either exists"
      field :favorite_count, Integer, null: false, description: "Number of times this puzzle has been favorited"
      field :featured, Boolean, null: false, description: "Whether an admin has featured this puzzle"
      field :folder, FolderType, null: true,
        description: "Folder this puzzle is filed in; only visible to the author"
      field :given_digits, GraphQL::Types::JSON, null: false,
        description: "Pre-filled clue digits keyed by cell coordinate (r0c0: 5)"
      field :granted_users, [ UserType ], null: false,
        description: "Users explicitly granted access to this private puzzle; only visible to the author"
      field :grid, GridType, null: false, description: "Grid dimensions"
      field :has_solution_code, Boolean, null: false,
        description: "Whether the published version accepts an off-site solution code to claim a solve"
      field :id, ID, null: false, description: "Unique puzzle ID"
      field :is_favorited, Boolean, null: false,
        description: "Whether the current user has favorited this puzzle"
      field :my_rating, RatingType, null: true, description: "Current user's rating for this puzzle"
      field :page_description_html, String, null: true,
        description: "Sanitized rich author description (HTML) shown on the public puzzle page"
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
      field :status, Types::Enums::PuzzleStatusEnum, null: false, description: "Lifecycle status: draft or published"
      field :sudokupad_includes_solution, Boolean, null: false,
        description: "Whether the SudokuPad link embeds the solution (so SudokuPad can solve-check)"
      field :sudokupad_url, String, null: true,
        description: "Short SudokuPad link for this puzzle, or null when none is available (e.g. a non-square grid)"
      field :tags, [ TagType ], null: false, description: "Tags categorizing this puzzle"
      field :title, String, null: false, description: "Puzzle title"
      field :versions, [ PuzzleVersionType ], null: false,
        description: "All saved versions, oldest first; only visible to the author"
      field :viewer_has_solved, Boolean, null: false,
        description: "Whether the current user has completed this puzzle (drives the comment composer gate)"
      field :visibility, Types::Enums::PuzzleVisibilityEnum, null: false,
        description: "Access mode: private, unlisted, public, patrons_only, subscribers_only, or containers_only"

      def grid
        { rows: object.grid_rows, cols: object.grid_cols }
      end

      def has_solution_code
        object.published_version&.solution_code.present?
      end

      # The setter's free-text credit lives in the published version's definition
      # (meta.author); blank means "attribute to my display name" — the frontend
      # applies that fallback so it can link the display name to the profile.
      def author_name
        name = object.published_version&.definition&.dig("meta", "author")
        name.strip.presence if name.is_a?(String)
      end

      def solution
        return object.solution if author_or_admin?

        nil
      end

      # Container-only puzzles surface their token to any viewer who reached them
      # through a container they can see, so the client can build a working play
      # link. (Plain unlisted puzzles keep the token author-only — it's the secret
      # that gates their link.)
      def share_token
        return object.share_token if author_or_admin? || object.visible_containers_only?

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

      def comments_require_solve_override
        object.comments_require_solve_override if author_or_admin?
      end

      def viewer_has_solved
        object.solved_by?(Actor.from_context(current_user: context[:current_user], guest_token: context[:guest_token]))
      end

      def sudokupad_url
        return nil unless sudokupad_available?

        serving_solution_link? ? object.sudokupad_solution_url : object.sudokupad_url
      end

      def sudokupad_includes_solution
        sudokupad_available? && serving_solution_link?
      end

      private

      def author_or_admin?
        context[:current_user]&.id == object.author_id || context[:current_user]&.admin?
      end

      # Never surface a SudokuPad link for an unreachable puzzle. (The query
      # already gates viewability; this guards the raw fields independently.)
      def sudokupad_available?
        return false if object.draft? || object.visible_private?

        (serving_solution_link? ? object.sudokupad_solution_url : object.sudokupad_url).present?
      end

      # The solution-embedded link is served only when the author opted in AND we
      # actually built one; otherwise we serve the solution-less link.
      def serving_solution_link?
        object.author.include_solution_in_sudokupad_export && object.sudokupad_solution_url.present?
      end
    end
  end
end
