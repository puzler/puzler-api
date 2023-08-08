# frozen_string_literal: true

module Schemas
  module Auth
    module AuthQueries
      include Interfaces::BaseInterface

      field :me, Types::User, null: true

      def me
        current_user
      end
    end
  end
end
