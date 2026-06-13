module Types
  module Objects
    class TagType < BaseObject
      description "A tag used to categorize puzzles in the archive"

      field :id, ID, null: false, description: "Unique tag ID"
      field :name, String, null: false, description: "Human-readable tag label"
      field :puzzle_count, Integer, null: false,
        description: "Number of published or featured puzzles with this tag"
      field :slug, String, null: false, description: "URL-safe tag identifier"

      def puzzle_count
        object.puzzles.publicly_visible.count
      end
    end
  end
end
