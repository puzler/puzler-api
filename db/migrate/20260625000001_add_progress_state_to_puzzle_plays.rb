class AddProgressStateToPuzzlePlays < ActiveRecord::Migration[8.1]
  # The full solving session beyond the bare cell map: serialized undo/redo
  # history, timer pause-state, selection, input mode, palette page, and a
  # published-version fingerprint. Schemaless sub-data owned by the frontend
  # (utils/solveSession.ts defines its shape); the API stores it verbatim.
  # `cell_state` stays the authoritative cell map so submit/check_solution's
  # server-side validation is unaffected.
  def change
    add_column :puzzle_plays, :progress_state, :jsonb, null: false, default: {}

    # Resuming looks up a signed-in user's single unsolved play for a puzzle.
    add_index :puzzle_plays, [ :puzzle_id, :user_id ],
      where: "is_solved = false",
      name: "index_puzzle_plays_active_by_user"
  end
end
