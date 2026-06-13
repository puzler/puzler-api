class CreateSeriesEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :series_entries do |t|
      t.references :series, null: false, foreign_key: true
      t.references :entryable, null: false, polymorphic: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :series_entries, [ :series_id, :position ]
    # An entry (a given puzzle or collection) appears at most once per series.
    add_index :series_entries, [ :series_id, :entryable_type, :entryable_id ], unique: true,
      name: "index_series_entries_unique"
  end
end
