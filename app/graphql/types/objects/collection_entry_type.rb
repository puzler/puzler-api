module Types
  module Objects
    class CollectionEntryType < BaseObject
      description "One ordered item in a collection — a puzzle or a story page"

      field :entry_type, String, null: false, method: :entryable_type,
        description: "What this entry points at: Puzzle or StoryPage"
      field :id, ID, null: false, description: "Unique entry ID"
      field :position, Integer, null: false, description: "Order within the collection"
      field :puzzle, PuzzleType, null: true,
        description: "The puzzle, when this entry is a puzzle"
      field :story_page, StoryPageType, null: true,
        description: "The story page, when this entry is a story page"

      def puzzle
        object.entryable if object.entryable_type == "Puzzle"
      end

      def story_page
        object.entryable if object.entryable_type == "StoryPage"
      end
    end
  end
end
