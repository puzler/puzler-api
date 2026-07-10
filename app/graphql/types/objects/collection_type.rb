module Types
  module Objects
    class CollectionType < BaseObject
      description "An ordered, shareable grouping of puzzles (a series)"

      field :accent_color, Types::Enums::CollectionAccentColorEnum, null: false,
        description: "Curated accent color for the collection page"
      field :author, UserType, null: false, description: "The setter who owns the collection"
      field :avg_rating, Float, null: true, description: "Average star rating across member puzzles (1-5 scale)"
      field :bg_treatment, Types::Enums::CollectionBgTreatmentEnum, null: false,
        description: "Curated background treatment for the collection page"
      field :cover_image_url, String, null: true,
        description: "Hosted URL of the cover image, page-hero size; null when unset"
      field :cover_thumb_url, String, null: true,
        description: "Hosted URL of the cover image, 16:9 card crop; null when unset"
      field :description, String, null: true, description: "Optional short description (plain text, shown on cards)"
      field :folder, FolderType, null: true,
        description: "Folder this collection is filed in; only visible to the author"
      field :id, ID, null: false, description: "Unique collection ID"
      field :mode, Types::Enums::CollectionModeEnum, null: false, description: "Ordering mode: unordered or sequence"
      field :page_description_html, String, null: true,
        description: "Sanitized rich HTML body for the collection page"
      field :puzzle_count, Integer, null: false, description: "Number of puzzles the viewer can see in this collection"
      field :puzzles, [ PuzzleType ], null: false,
        description: "Puzzles in order; non-authors see only the publicly-visible ones"
      field :share_token, String, null: true,
        description: "Unguessable share key for unlisted access; only visible to the author"
      field :solve_count, Integer, null: false, description: "Total solves across member puzzles"
      field :timed, Boolean, null: false, description: "Whether solves are timed (competition mode)"
      field :title, String, null: false, description: "Collection title"
      field :title_font, Types::Enums::CollectionTitleFontEnum, null: false,
        description: "Curated display font for the collection page title"
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

      def folder
        object.folder if author_or_admin?
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
