class CreateSeriesSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :series_subscriptions do |t|
      t.references :series, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # One subscription per user per series.
    add_index :series_subscriptions, [ :series_id, :user_id ], unique: true
  end
end
