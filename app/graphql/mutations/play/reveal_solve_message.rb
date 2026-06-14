module Mutations
  module Play
    class RevealSolveMessage < Mutations::BaseMutation
      description "Reveal a puzzle's custom solve message, only for a correct solution"

      argument :puzzle_id, ID, required: true, description: "ID of the solved puzzle"
      argument :share_token, String, required: false,
        description: "Share token, required to reach an unlisted puzzle"
      argument :solution_hash, String, required: true,
        description: "SHA-256 of the submitted board; must match the published solution"

      field :correct, Boolean, null: false, description: "Whether the submitted hash matches the solution"
      field :solve_message, String, null: true,
        description: "The author's custom message, present only on a correct solve with a non-blank message"

      def resolve(puzzle_id:, solution_hash:, share_token: nil)
        puzzle = Puzzle.find_by(id: puzzle_id)
        return { correct: false, solve_message: nil } unless puzzle&.viewable_by?(current_user, share_token:)

        version = puzzle.published_version
        stored = version&.solution_hash
        correct = stored.present? && ActiveSupport::SecurityUtils.secure_compare(stored, solution_hash)

        { correct:, solve_message: correct ? version.solve_message.presence : nil }
      end
    end
  end
end
