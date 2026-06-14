module Types
  module Objects
    class CollectionType < BaseObject
      description "An ordered, shareable grouping of puzzles (a series)"

      field :author, UserType, null: false, description: "The setter who owns the collection"
      field :description, String, null: true, description: "Optional description"
      field :id, ID, null: false, description: "Unique collection ID"
      field :mode, Types::Enums::CollectionModeEnum, null: false, description: "Ordering mode: unordered or sequence"
      field :puzzle_count, Integer, null: false, description: "Number of puzzles the viewer can see in this collection"
      field :puzzles, [ PuzzleType ], null: false,
        description: "Puzzles in order; non-authors see only the publicly-visible ones"
      field :share_token, String, null: true,
        description: "Unguessable share key for unlisted access; only visible to the author"
      field :timed, Boolean, null: false, description: "Whether solves are timed (competition mode)"
      field :title, String, null: false, description: "Collection title"
      field :visibility, Types::Enums::CollectionVisibilityEnum, null: false,
        description: "Access mode: private, unlisted, public, patrons_only, subscribers_only, or containers_only"

      def puzzles
        visible_puzzles
      end

      def puzzle_count
        visible_puzzles.size
      end

      # Container-only collections surface their token to any viewer who reached
      # them through a series they can see, so the client can build a working
      # link. (Plain unlisted collections keep the token author-only.)
      def share_token
        object.share_token if author_or_admin? || object.visible_containers_only?
      end

      private

      # Authors see every puzzle in the collection (incl. drafts); everyone else
      # sees the public ones plus container-only puzzles (which exist to be shown
      # exactly here), preserving collection order.
      def visible_puzzles
        author_or_admin? ? object.puzzles : object.puzzles.container_visible
      end

      def author_or_admin?
        context[:current_user]&.id == object.author_id || context[:current_user]&.admin?
      end
    end
  end
end
