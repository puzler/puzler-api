class AddVisibilityToPuzzles < ActiveRecord::Migration[8.0]
  def up
    add_column :puzzles, :visibility, :integer, null: false, default: 0
    add_column :puzzles, :featured, :boolean, null: false, default: false
    add_index :puzzles, :visibility

    # Two-axis migration: the old status=2 (featured) collapses into
    # status=published plus the new featured flag.
    execute "UPDATE puzzles SET featured = true, status = 1 WHERE status = 2"
    # Previously, published puzzles were visible to everyone — that's public.
    execute "UPDATE puzzles SET visibility = 2 WHERE status = 1"

    remove_column :puzzles, :patron_visibility
  end

  def down
    add_column :puzzles, :patron_visibility, :integer, default: 0
    execute "UPDATE puzzles SET status = 2 WHERE featured = true"
    remove_index :puzzles, :visibility
    remove_column :puzzles, :featured
    remove_column :puzzles, :visibility
  end
end
