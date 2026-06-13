class AddVersionCounterToPuzzles < ActiveRecord::Migration[8.0]
  def change
    # Monotonic source for version_number so numbers are never reused, even after
    # a version is deleted.
    add_column :puzzles, :version_counter, :integer, null: false, default: 0
  end
end
