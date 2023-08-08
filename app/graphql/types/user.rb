# frozen_string_literal: true

module Types
  class User < BaseType
    field :id, ID, null: false
    field :email, String, null: false
    field :display_name, String, null: false
    field :first_name, String, null: true
    field :last_name, String, null: true
  end
end
