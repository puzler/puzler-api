# frozen_string_literal: true

module Schemas
  module Puzzles
    module PuzzleQueries
      include Interfaces::BaseInterface

      description 'Base Query object for Puzzles'

      field :fetch_puzzle,
            Types::Puzzle,
            null: true,
            description: 'Fetch a Puzzle' do
              argument :id, ID, required: true, description: 'The ID of the puzzle to fetch'
            end

      field :load_f_puzzle,
            Types::Puzzle,
            null: true,
            description: 'Load a Puzzle from FPuzzles from a compressed Base64 string' do
              argument :base64_data,
                       String,
                       required: true,
                       description: 'Compressed Base64 string containing the FPuzzles puzzle data'
            end

      def fetch_puzzle(id:)
        puzzle = Puzzle.find_by(id:)
        return if puzzle.nil?
        return if puzzle.private_vis? && current_user.id != puzzle.user_id

        puzzle
      end

      def load_f_puzzle(base64_data:)
        FPuzzle::Converter.new.from_f_puzzle(base64_data)
      end
    end
  end
end
