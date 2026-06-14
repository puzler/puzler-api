module Types
  module Objects
    class FolderType < BaseObject
      description "A private folder for organizing a setter's own puzzles"

      field :id, ID, null: false, description: "Unique folder ID"
      field :name, String, null: false, description: "Folder name"
      field :position, Integer, null: false, description: "Sort position among the author's folders"
      field :puzzle_count, Integer, null: false, description: "Number of puzzles filed in this folder"

      def puzzle_count
        object.puzzles.size
      end
    end
  end
end
