# frozen_string_literal: true

module InputObjects
  class PuzzleInput < BaseInputObject
    description 'Input for a Puzzle'

    argument :author, String, required: false, description: 'Puzzle Author'
    argument :rules, String, required: false, description: 'Puzzle Rules'
    argument :size, Integer, required: true, description: 'Puzzle Size'
    argument :title, String, required: false, description: 'Puzzle Title'

    argument :cells,
             [[InputObjects::Puzzles::GridCellInput]],
             required: true,
             description: 'Given Digits'

    argument :global_constraints,
             InputObjects::Puzzles::GlobalConstraintsInput,
             required: false,
             description: 'Global Constraints'

    argument :local_constraints,
             InputObjects::Puzzles::LocalConstraintsInput,
             required: false,
             description: 'Local Constratints'

    argument :cosmetics,
             InputObjects::Puzzles::CosmeticElementsInput,
             required: false,
             description: 'Cosmetic Elements'
  end
end
