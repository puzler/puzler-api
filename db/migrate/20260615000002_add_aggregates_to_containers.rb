class AddAggregatesToContainers < ActiveRecord::Migration[8.1]
  # Denormalized rating/solve aggregates, derived from member puzzles, so
  # collections and series can be sorted by rating/popularity the same way
  # puzzles are (Puzzle#by_rating / Puzzle#by_popularity) without a per-request
  # subquery across large, paginated lists.
  def change
    add_column :collections, :avg_rating, :float
    add_column :collections, :solve_count, :integer, default: 0, null: false
    add_column :series, :avg_rating, :float
    add_column :series, :solve_count, :integer, default: 0, null: false
  end
end
