module Types
  module Objects
    class CommentType < BaseObject
      description "A comment on a puzzle"

      field :body, String, null: false,
        description: "Comment text; spoiler content is redacted for viewers who have not solved the puzzle"
      field :can_delete, Boolean, null: false,
        description: "Whether the current viewer may delete this comment"
      field :can_mark_spoiler, Boolean, null: false,
        description: "Whether the current viewer may mark or unmark this comment as a spoiler"
      field :commenter_solved, Boolean, null: false,
        description: "Whether the commenter has completed this puzzle (drives the 'solved' badge)"
      field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When the comment was posted"
      field :id, ID, null: false, description: "Unique comment ID"
      field :is_author, Boolean, null: false,
        description: "Whether the commenter is the puzzle's author"
      field :is_spoiler, Boolean, null: false, method: :spoiler?,
        description: "Whether the whole comment is flagged as a spoiler"
      field :parent_id, ID, null: true, description: "ID of the parent comment if this is a reply"
      field :puzzle, PuzzleType, null: false, description: "The puzzle this comment is on"
      field :replies, [ CommentType ], null: false, description: "Direct replies to this comment"
      field :segments, [ CommentSegmentType ], null: false,
        description: "The body split into text and spoiler runs, spoilers redacted per viewer"
      field :spoiler_marked_by_setter, Boolean, null: false,
        description: "Whether the spoiler flag was applied by someone other than the commenter (the setter or an admin)"
      field :spoilers_redacted, Boolean, null: false,
        description: "True when this viewer cannot see the comment's spoiler content"
      field :user, UserType, null: false, description: "User who posted the comment"

      REDACTED_SECTION = "[spoiler]".freeze

      # The plain body stays safe for legacy selections (e.g. profile activity):
      # whole-comment spoilers serialize empty, sections collapse to a marker.
      def body
        return object.body unless redact_spoilers?
        return "" if object.spoiler?

        object.segments.map { |kind, text| kind == :spoiler ? REDACTED_SECTION : text }.join
      end

      def segments
        redact = redact_spoilers?
        object.segments.map do |kind, text|
          spoiler = kind == :spoiler
          hidden = spoiler && redact
          { spoiler:, redacted: hidden, text: hidden ? nil : text }
        end
      end

      def spoilers_redacted
        object.spoilers? && redact_spoilers?
      end

      def spoiler_marked_by_setter
        object.spoiler? && object.spoiler_marked_by_id != object.user_id
      end

      def can_delete
        context[:current_user]&.id == object.user_id
      end

      def can_mark_spoiler
        user = context[:current_user]
        return false unless user
        return true if user.admin? || user.id == object.user_id

        loaded_puzzle&.author_id == user.id
      end

      # Live, batched: a commenter who solves after posting still gets the badge.
      def commenter_solved
        context.dataloader.with(Sources::PuzzleSolve, object.puzzle_id).load(object.user_id)
      end

      def is_author
        loaded_puzzle&.author_id == object.user_id
      end

      private

      def loaded_puzzle
        context.dataloader.with(Sources::Record, Puzzle).load(object.puzzle_id)
      end

      # Memoized per puzzle for the whole request (mirrors CompetitionGuard), so a
      # busy thread costs one solved-check per puzzle, not per comment.
      def redact_spoilers?
        cache = context[:comment_spoiler_access] ||= {}
        visible = cache.fetch(object.puzzle_id) do
          actor = Actor.from_context(current_user: context[:current_user], guest_token: context[:guest_token])
          cache[object.puzzle_id] = loaded_puzzle&.solved_by?(actor) ||
            (context[:current_user]&.admin? || false) ||
            loaded_puzzle&.author_id == context[:current_user]&.id
        end
        # The commenter always sees their own spoilers, independent of the
        # per-puzzle cache.
        return false if context[:current_user]&.id == object.user_id

        !visible
      end
    end
  end
end
