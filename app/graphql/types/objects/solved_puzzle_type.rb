module Types
  module Objects
    # A puzzle this user has solved, optionally paired with the rating and review
    # THEY left on it. The owner's rating/review are populated only at the
    # "detailed" disclosure level (or for the owner viewing their own profile);
    # see UserType#solved_puzzles. Resolved from a plain hash built there (each
    # field reads the matching hash key by default).
    class SolvedPuzzleType < BaseObject
      description "A puzzle the user has solved, with the rating and review they left"

      field :owner_rating, RatingType, null: true,
        description: "The profile owner's rating, shown only at the detailed disclosure level"
      field :owner_review, CommentType, null: true,
        description: "The profile owner's review, shown only at the detailed disclosure level"
      field :puzzle, PuzzleType, null: false, description: "The solved puzzle"
    end
  end
end
