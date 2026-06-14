class CreateCollections < ActiveRecord::Migration[8.0]
  def change
    create_table :collections do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.integer :visibility, null: false, default: 0
      t.integer :mode, null: false, default: 0
      t.string :share_token

      t.timestamps
    end

    add_index :collections, :share_token, unique: true
    add_index :collections, :visibility
    add_index :collections, :mode
  end
end
