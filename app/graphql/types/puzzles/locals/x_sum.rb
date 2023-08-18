# frozen_string_literal: true

module Types
  module Puzzles
    module Locals
      class XSum < BaseType
        implements Interfaces::Puzzles::NumberOutsideGrid

        description 'An X-Sum clue'
      end
    end
  end
end
