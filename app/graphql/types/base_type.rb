# frozen_string_literal: true

module Types
  class BaseType < BaseObject
    def current_user
      context[:current_user]
    end
  end
end
