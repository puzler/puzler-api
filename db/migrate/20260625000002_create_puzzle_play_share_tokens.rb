class CreatePuzzlePlayShareTokens < ActiveRecord::Migration[8.1]
  # A short, unguessable capability to JOIN a play session as a co-solver. The
  # owner generates one from the collaboration modal; it can be single-use (links
  # to the consumer and locks) or multi-use, and is revocable. Mirrors the
  # share_token generator on puzzles/collections.
  def change
    create_table :puzzle_play_share_tokens do |t|
      t.references :puzzle_play, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :consumed_by, null: true, foreign_key: { to_table: :users }
      t.string :token, null: false
      t.boolean :single_use, null: false, default: false
      t.datetime :consumed_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :puzzle_play_share_tokens, :token, unique: true
  end
end
