module Mutations
  module Puzzles
    # Save the rich description for a puzzle's public page (author only). The HTML
    # is sanitized server-side before storage, and orphaned uploaded images are
    # purged so removing an image from the doc cleans up its blob.
    class UpdatePageDescription < Mutations::BaseMutation
      description "Save the sanitized rich description for a puzzle's public page"

      argument :html, String, required: true,
        description: "Raw TipTap HTML; sanitized server-side before it is stored"
      argument :puzzle_id, ID, required: true, description: "Puzzle to update"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true, description: "The updated puzzle"

      def resolve(puzzle_id:, html:)
        puzzle = require_owned!(:puzzles, "Puzzle", id: puzzle_id)

        clean = HtmlSanitizer.sanitize(html, allowed_image_hosts: DescriptionImageHost.allowed)
        if puzzle.update(page_description_html: clean)
          puzzle.reconcile_description_images!
          { puzzle:, errors: [] }
        else
          { puzzle: nil, errors: puzzle.errors.full_messages }
        end
      rescue HtmlSanitizer::TooLarge => e
        { puzzle: nil, errors: [ e.message ] }
      end
    end
  end
end
