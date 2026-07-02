module Types
  module Objects
    # One item in a user's recent public activity feed: a published puzzle, a
    # review they wrote, or a puzzle they solved. Resolved from a
    # UserActivityFeed::Event (each field calls the matching struct reader).
    # The associated puzzle is always present; comment is present only for
    # REVIEW_WRITTEN items.
    class ProfileActivityType < BaseObject
      description "A single item in a user's recent public activity feed"

      field :comment, CommentType, null: true, description: "The review written, for REVIEW_WRITTEN items"
      field :kind, Types::Enums::ProfileActivityKindEnum, null: false, description: "The kind of activity"
      field :occurred_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When the activity happened"
      field :puzzle, PuzzleType, null: true, description: "The puzzle this activity concerns"
    end
  end
end
