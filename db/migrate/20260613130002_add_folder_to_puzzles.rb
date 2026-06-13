class AddFolderToPuzzles < ActiveRecord::Migration[8.0]
  def change
    # Single-folder membership; deleting a folder leaves its puzzles unfiled.
    add_reference :puzzles, :folder, null: true, foreign_key: { on_delete: :nullify }
  end
end
