module Types
  module Objects
    class FolderType < BaseObject
      description "A private folder for organizing a setter's own puzzles and collections"

      field :children, [ FolderType ], null: false, description: "Nested sub-folders, in sort order"
      field :collection_count, Integer, null: false, description: "Number of collections filed in this folder"
      field :id, ID, null: false, description: "Unique folder ID"
      field :name, String, null: false, description: "Folder name"
      field :parent_id, ID, null: true, description: "Parent folder ID, or null when at the top level"
      field :position, Integer, null: false, description: "Sort position among sibling folders"
      field :puzzle_count, Integer, null: false, description: "Number of puzzles filed in this folder"

      def children
        object.children.order(:position)
      end

      def puzzle_count
        object.puzzles.size
      end

      def collection_count
        object.collections.size
      end
    end
  end
end
