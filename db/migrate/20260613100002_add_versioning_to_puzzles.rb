class AddVersioningToPuzzles < ActiveRecord::Migration[8.0]
  def up
    # published_version is nullified (not cascaded) when a version is destroyed,
    # which also lets a puzzle destroy its versions without an FK violation.
    add_reference :puzzles, :published_version, null: true,
      foreign_key: { to_table: :puzzle_versions, on_delete: :nullify }
    add_column :puzzles, :share_token, :string
    add_column :puzzles, :constraint_types, :string, array: true, null: false, default: []

    # Backfill an unguessable share token for any pre-existing puzzles.
    Puzzle.reset_column_information
    Puzzle.where(share_token: nil).find_each do |puzzle|
      puzzle.update_columns(share_token: SecureRandom.urlsafe_base64(16))
    end

    add_index :puzzles, :share_token, unique: true
    add_index :puzzles, :constraint_types, using: :gin
  end

  def down
    remove_index :puzzles, :constraint_types
    remove_index :puzzles, :share_token
    remove_column :puzzles, :constraint_types
    remove_column :puzzles, :share_token
    remove_reference :puzzles, :published_version,
      foreign_key: { to_table: :puzzle_versions }
  end
end
