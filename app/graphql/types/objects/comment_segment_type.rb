module Types
  module Objects
    class CommentSegmentType < BaseObject
      description "One run of a comment body: plain text, or a spoiler span " \
        "whose text is withheld from viewers who have not solved the puzzle"

      field :redacted, Boolean, null: false,
        description: "True when the span's text was withheld server-side"
      field :spoiler, Boolean, null: false,
        description: "Whether this span is a spoiler (render click-to-reveal even when text is present)"
      field :text, String, null: true,
        description: "The span's text; null exactly when redacted"
    end
  end
end
