# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Locals
      class XVInput < MultiCellInput
        description 'Input for an XV element'

        argument :xv_type,
                 Enums::Puzzles::XVTypes,
                 required: false,
                 description: 'Element is an X or a V'
      end
    end
  end
end
