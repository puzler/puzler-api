# frozen_string_literal: true

module Types
  module Puzzles
    module Locals
      class Quadruple < BaseType
        implements Interfaces::Puzzles::MultiCell
        field :values, [Integer], null: false, description: 'Values in the Quadruple'

        description 'A Quadruple clue'
      end
    end
  end
end