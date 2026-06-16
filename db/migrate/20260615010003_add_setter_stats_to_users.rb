class AddSetterStatsToUsers < ActiveRecord::Migration[8.1]
  # Denormalized "setter score" + tier, blending an author's published-puzzle
  # volume with their recency-weighted average rating, so the archive can filter
  # by setter experience with an indexed WHERE rather than a live aggregate.
  def change
    add_column :users, :setter_score, :float, default: 0.0, null: false
    add_column :users, :setter_tier, :integer, default: 0, null: false
    add_index :users, :setter_tier
  end
end
