class SudokupadLinkRefreshJob < ApplicationJob
  queue_as :default

  # Rebuild a puzzle's cached SudokuPad links (used for backfill and when an
  # author changes their solution-export setting). Each call hits createlink, so
  # this runs async off the request path.
  def perform(puzzle_id)
    Puzzle.find_by(id: puzzle_id)&.refresh_sudokupad_links!
  end
end
