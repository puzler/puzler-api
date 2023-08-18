# frozen_string_literal: true

module Interfaces
  module Puzzles
    module SingleCell
      include BaseInterface
      description 'An element that references a single cell'
      field :cell, Types::Puzzles::Address, null: false, description: 'Cell Address'
    end
  end
end
