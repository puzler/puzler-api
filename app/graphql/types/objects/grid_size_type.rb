module Types
  module Objects
    # A distinct grid size present in the archive, with how many puzzles use it.
    # Drives the archive's grid-size facet.
    class GridSizeType < BaseObject
      description "A grid dimension present in the archive and its puzzle count"

      field :cols, Integer, null: false, description: "Number of columns"
      field :count, Integer, null: false, description: "Published puzzles with this size"
      field :rows, Integer, null: false, description: "Number of rows"
    end
  end
end
