# frozen_string_literal: true

module Mutations
  module Puzzles
    class SavePuzzle < BaseMutation
      description 'Save a puzzle. If ID is not given, puzzle is saved as a new puzzle.'

      argument :puzzle,
               InputObjects::PuzzleInput,
               required: true,
               description: 'The Puzzle to save'

      field :puzzle, Types::Puzzle, null: true, description: 'The new saved puzzle'
      authenticated true

      def resolve(puzzle:)
        id = puzzle.id
        record = Puzzle.find(id) if id.present?
        return error('Not Found') if id.present? && record.nil?

        if record.present?
          return error('Unauthorized') if current_user.id != record.user_id

          record.update(puzzle.to_h)
        else
          record ||= Puzzle.create(
            puzzle.to_h.merge(user_id: current_user.id)
          )
        end

        return errors_for(record) if record.errors.any?

        {
          success: true,
          puzzle: record
        }
      end
    end
  end
end
