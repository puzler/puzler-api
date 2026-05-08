module Types
  module Objects
    class GridType < BaseObject
      description "Grid dimensions for a puzzle"

      field :cols, Integer, null: false, description: "Number of columns"
      field :rows, Integer, null: false, description: "Number of rows"
    end
  end
end
