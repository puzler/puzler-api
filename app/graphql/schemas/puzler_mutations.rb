# frozen_string_literal: true

module Schemas
  class PuzlerMutations < BaseObject
    description 'The base Mutation Object'

    implements Schemas::Auth::AuthMutations
    implements Schemas::Puzzles::PuzzleMutations
  end
end
