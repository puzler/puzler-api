# frozen_string_literal: true

module Types
  class User < BaseType
    field :display_name, String, null: false, description: "A User's display name"
    field :email, String, null: false, description: "A User's email"
    field :first_name, String, null: true, description: "A User's first name"
    field :id, ID, null: false, description: "A User's id"
    field :last_name, String, null: true, description: "A User's last name"

    description 'A User that can sign in'
  end
end
