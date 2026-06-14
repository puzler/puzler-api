# frozen_string_literal: true

module Types
  module Enums
    class BaseEnum < GraphQL::Schema::Enum
      class << self
        private

        def generate_from_rails_enum(enum)
          enum.each_key do |enum_val|
            value enum_val.upcase, value: enum_val
          end
        end
      end
    end
  end
end
