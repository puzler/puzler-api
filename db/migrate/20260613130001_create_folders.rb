class CreateFolders < ActiveRecord::Migration[8.0]
  def change
    create_table :folders do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }
      # Self-reference reserved for nested folders (Phase 1 leaves it null).
      t.references :parent, null: true, foreign_key: { to_table: :folders, on_delete: :nullify }
      t.string :name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :folders, [ :author_id, :position ]
  end
end
