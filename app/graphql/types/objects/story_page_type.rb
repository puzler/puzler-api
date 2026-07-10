module Types
  module Objects
    class StoryPageType < BaseObject
      description "A narrative interlude between puzzles in a collection"

      field :body_html, String, null: true,
        description: "Sanitized rich HTML body of the story page"
      field :id, ID, null: false, description: "Unique story page ID"
      field :title, String, null: true,
        description: "Optional heading; titled pages appear in the table of contents"
    end
  end
end
