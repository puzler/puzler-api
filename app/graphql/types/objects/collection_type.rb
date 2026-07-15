module Types
  module Objects
    class CollectionType < BaseObject
      description "An ordered, shareable grouping of puzzles (a series)"

      # Teaser mode for patrons_only collections: entries/body withhold below
      # when the viewer doesn't pass the patron gate.
      include PatronGating

      field :accent_color, Types::Enums::CollectionAccentColorEnum, null: false,
        description: "Curated accent color for the collection page"
      field :author, UserType, null: false, description: "The setter who owns the collection"
      field :avg_rating, Float, null: true, description: "Average star rating across member puzzles (1-5 scale)"
      field :bg_treatment, Types::Enums::CollectionBgTreatmentEnum, null: false,
        description: "Curated background treatment for the collection page"
      field :competition_config, CompetitionConfigType, null: true,
        description: "Contest terms; present only for competition collections"
      field :cover_image_url, String, null: true,
        description: "Hosted URL of the cover image, page-hero size; null when unset"
      field :cover_thumb_url, String, null: true,
        description: "Hosted URL of the cover image, 16:9 card crop; null when unset"
      field :description, String, null: true, description: "Optional short description (plain text, shown on cards)"
      field :effective_release_at, GraphQL::Types::ISO8601DateTime, null: true,
        description: "When this became (or becomes) available: the scheduled release, else creation"
      field :entries, [ CollectionEntryType ], null: false,
        description: "Ordered entries (puzzles and story pages) with the viewer's lock state resolved; " \
                     "non-authors see only publicly-visible puzzles, and hidden entries only once unlocked"
      field :folder, FolderType, null: true,
        description: "Folder this collection is filed in; only visible to the author"
      field :has_codewords, Boolean, null: false,
        description: "Whether any entry is gated by a codeword (drives the codeword input)"
      field :id, ID, null: false, description: "Unique collection ID"
      field :is_released, Boolean, null: false,
        description: "Whether the scheduled release moment has passed (always true when unscheduled)"
      field :kind, Types::Enums::CollectionKindEnum, null: false,
        description: "What this collection is: basic list, hunt, or competition"
      field :mode, Types::Enums::CollectionModeEnum, null: false, description: "Ordering mode: unordered or sequence"
      field :my_competition_run, CompetitionRunType, null: true,
        description: "The viewer's run on this competition, finalized if it has ended; null before they start"
      field :next_release_at, GraphQL::Types::ISO8601DateTime, null: true,
        description: "When the next scheduled entry arrives; null when nothing is pending"
      field :page_description_html, String, null: true,
        description: "Sanitized rich HTML body for the collection page"
      field :patron_access, PatronAccessType, null: true,
        description: "The viewer's standing against the patron gate; null unless patrons_only"
      field :patron_gate, PatronGateType, null: true,
        description: "Who qualifies when patrons_only; null means the default gate (any paying patron)"
      field :puzzle_count, Integer, null: false, description: "Number of puzzles the viewer can see in this collection"
      field :puzzles, [ PuzzleType ], null: false,
        description: "Puzzles in order; non-authors see only the publicly-visible ones"
      field :released_at, GraphQL::Types::ISO8601DateTime, null: true,
        description: "Scheduled release time; only visible to the author"
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
        return Puzzle.none if teaser_locked?

        visible_puzzles
      end

      # Story pages always show inside their collection; puzzle entries follow
      # the same visibility rule as `puzzles`. CollectionGate then resolves the
      # viewer's per-entry lock state (sequence, codewords, hidden, finale, or
      # competition run state, per the collection's kind). Patron-gated member
      # puzzles the viewer doesn't qualify for surface as locked teaser rows
      # (or are omitted when teaser settings say so).
      def entries
        return [] if teaser_locked?

        actor = Actor.from_context(current_user: context[:current_user], guest_token: context[:guest_token])
        gated = CollectionGate.new(object, actor:, author_view: author_or_admin?, competition_run: viewer_run)
                              .call(entries_visible_to_viewer)
        mark_patron_locked(gated)
      end

      def competition_config
        object if object.kind_competition?
      end

      def my_competition_run
        viewer_run&.ensure_finalized!
      end

      def has_codewords
        return false if teaser_locked?

        object.entries.where.not(codeword_digest: nil).exists?
      end

      def page_description_html
        object.page_description_html unless teaser_locked?
      end

      # The next scheduled arrival worth teasing. Hidden entries stay secret
      # even in schedule form.
      def next_release_at
        object.entries.where(hidden: false).where("released_at > ?", Time.current).minimum(:released_at)
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

      # Entries whose existence the viewer may know about: story pages always,
      # puzzle entries per visible_puzzles.
      def entries_visible_to_viewer
        loaded = object.entries.includes(:entryable)
        return loaded.to_a if author_or_admin?

        visible_ids = visible_puzzles.pluck(:id).to_set
        loaded.select do |entry|
          entry.entryable_type == "StoryPage" || visible_ids.include?(entry.entryable_id)
        end
      end

      # Authors see every puzzle in the collection (incl. drafts); everyone else
      # sees the public ones, container-only puzzles (which exist to be shown
      # exactly here), and patron-gated puzzles — the latter render as locked
      # teaser rows when the viewer doesn't pass their gate.
      def visible_puzzles
        return object.puzzles if author_or_admin?

        object.puzzles
          .where(status: :published, visibility: [ :public, :containers_only, :patrons_only ])
          .released
      end

      # Flag puzzle entries whose patron gate the viewer doesn't pass. Locked
      # teaser rows stay listed only where teaser settings allow: the creator
      # kept teasers on and the viewer hasn't opted out.
      def mark_patron_locked(gated_entries)
        return gated_entries if author_or_admin?

        user = context[:current_user]
        checker = context[:patron_access] ||= PatronAccess.new(user)
        show_teasers = object.author&.patreon_campaign&.teasers_enabled? && !user&.hide_patron_teasers?

        gated_entries.filter_map do |gated|
          puzzle = gated.entryable
          unless gated.entryable_type == "Puzzle" && puzzle&.visible_patrons_only?
            next gated
          end

          if checker.satisfies?(puzzle)
            gated
          elsif show_teasers
            gated.patron_locked = true
            gated
          end
        end
      end

      def author_or_admin?
        context[:current_user]&.id == object.author_id || context[:current_user]&.admin?
      end

      def viewer_run
        return nil unless object.kind_competition? && context[:current_user]

        return @viewer_run if defined?(@viewer_run)

        @viewer_run = object.competition_runs.find_by(user: context[:current_user])
      end
    end
  end
end
