# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Cosmetics
      class TextInput < BaseInputObject
        description 'Input for a cosmetic text element'

        argument :address,
                 AddressInput,
                 required: true,
                 description: 'Text Location'

        argument :size, Float, required: true, description: 'Size of the text'
        argument :text, String, required: true, description: 'Text to display'

        argument :font_color,
                 ColorInput,
                 required: true,
                 description: 'Text Color'

        argument :angle, Float, required: false, description: 'Angle of Rotation'
      end
    end
  end
end
