class AddDescriptionAndSudokupadFieldsToPuzzles < ActiveRecord::Migration[8.1]
  # Fields for the public puzzle description page.
  #
  # page_description_html: author-written rich text (sanitized TipTap HTML),
  #   distinct from the short `description` (rules) shown in the solver. Lives on
  #   the puzzle (not a version) so it survives republishing a new version.
  #
  # comments_require_solve_override: per-puzzle override of the author's
  #   comments-require-solve default; null means "inherit the author's default".
  #
  # sudokupad_url / sudokupad_solution_url: short SudokuPad links built via the
  #   createlink API at publish time. The solution-less one is always created;
  #   the solution-embedded one only when the author opts in. (Long ?puzzleid=
  #   URLs are stored as a fallback if shortening fails.)
  def change
    add_column :puzzles, :page_description_html, :text
    add_column :puzzles, :comments_require_solve_override, :boolean
    add_column :puzzles, :sudokupad_url, :text
    add_column :puzzles, :sudokupad_solution_url, :text
  end
end
