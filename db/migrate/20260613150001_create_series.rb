class CreateSeries < ActiveRecord::Migration[8.0]
  def change
    create_table :series do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.integer :visibility, null: false, default: 0
      t.string :share_token, null: false

      t.timestamps
    end

    add_index :series, :visibility
    add_index :series, :share_token, unique: true
  end
end
