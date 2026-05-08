module Types
  module Objects
    class RatingType < BaseObject
      description "A player's star rating and difficulty assessment for a puzzle"

      field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this rating was submitted"
      field :difficulty_vote, String, null: true,
        description: "Difficulty assessment: easy, medium, hard, or expert"
      field :id, ID, null: false, description: "Unique rating ID"
      field :stars, Integer, null: true, description: "Star rating from 1 to 5"
      field :user, UserType, null: false, description: "User who submitted this rating"
    end
  end
end
