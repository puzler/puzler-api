# frozen_string_literal: true

module InputObjects
  module Puzzles
    class BaseLineInput < BaseInputObject
      argument :points, [AddressInput], required: true, description: 'Points along the line'
    end
  end
end
