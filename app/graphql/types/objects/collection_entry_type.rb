module Types
  module Objects
    # Backed by CollectionGate::GatedEntry, never a bare CollectionEntry: the
    # resolver wraps every entry with its per-actor lock state, and locked
    # story entries withhold their body here (titles stay for teasers/TOC).
    class CollectionEntryType < BaseObject
      description "One ordered item in a collection — a puzzle or a story page"

      field :entry_type, String, null: false, method: :entryable_type,
        description: "What this entry points at: Puzzle or StoryPage"
      field :finale, Boolean, null: false, method: :finale?,
        description: "Whether this entry unlocks only after every other puzzle is solved"
      field :gated, Boolean, null: false, method: :gated?,
        description: "Whether a codeword must be entered to open this entry"
      field :hidden, Boolean, null: false, method: :hidden?,
        description: "Whether this entry is invisible until its codeword is entered (authors always see it)"
      field :id, ID, null: false, description: "Unique entry ID"
      field :locked, Boolean, null: false,
        description: "Whether this entry is currently locked for the viewer"
      field :position, Integer, null: false, description: "Order within the collection"
      field :puzzle, PuzzleType, null: true,
        description: "The puzzle, when this entry is a puzzle"
      field :released_at, GraphQL::Types::ISO8601DateTime, null: true,
        description: "Scheduled release time; null means released on creation"
      field :solved, Boolean, null: false,
        description: "Whether the viewer has solved this entry's puzzle (always false for story pages)"
      field :story_page, StoryPageType, null: true,
        description: "The story page with its body, when this entry is an unlocked story page"
      field :story_title, String, null: true,
        description: "The story page's title, present even while the body is locked"

      def puzzle
        object.entryable if object.entryable_type == "Puzzle"
      end

      def story_page
        object.entryable if object.entryable_type == "StoryPage" && !object.locked
      end

      def story_title
        object.entryable.title if object.entryable_type == "StoryPage"
      end
    end
  end
end
