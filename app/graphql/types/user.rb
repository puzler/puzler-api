# frozen_string_literal: true

module Types
  class User < BaseType
    field :display_name, String, null: false, description: "A User's display name"
    field :email, String, null: true, description: "A User's email"
    field :first_name, String, null: true, description: "A User's first name"
    field :id, ID, null: false, description: "A User's id"
    field :last_name, String, null: true, description: "A User's last name"

    field :puzzles, [Puzzle], null: false, description: 'Puzzles made by the User'

    description 'A User that can sign in'

    def puzzles
      list = object.puzzles
      return list if current_user&.id == object.id

      list.public_vis
    end

    def email
      private_field :email
    end

    def first_name
      private_field :first_name
    end

    def last_name
      private_field :last_name
    end

    private

    def private_field(attribute)
      return unless current_user&.id == object.id

      object.send(attribute)
    end
  end
end
