# frozen_string_literal: true

module Enums
  module Puzzles
    class XVTypes < BaseEnum
      description 'Enum describing if an XV constraint is an X or a V'

      value 'X', value: 'X'
      value 'V', value: 'V'
    end
  end
end
