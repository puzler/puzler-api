# frozen_string_literal: true

module Schemas
  module Auth
    module AuthQueries
      include Interfaces::BaseInterface

      description 'Queries related to app authentication'

      field :me, Types::User, null: true, description: 'The currently logged in User'

      def me
        current_user
      end
    end
  end
end
