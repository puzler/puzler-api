module Types
  module Objects
    class SeriesEntryType < BaseObject
      description "One ordered item in a series — either a puzzle or a collection"

      field :collection, CollectionType, null: true,
        description: "The collection, when this entry is a collection"
      field :entry_type, String, null: false, method: :entryable_type,
        description: "What this entry points at: Puzzle or Collection"
      field :id, ID, null: false, description: "Unique entry ID"
      field :position, Integer, null: false, description: "Order within the series"
      field :puzzle, PuzzleType, null: true,
        description: "The puzzle, when this entry is a puzzle"

      def puzzle
        object.entryable if object.entryable_type == "Puzzle"
      end

      def collection
        object.entryable if object.entryable_type == "Collection"
      end
    end
  end
end
