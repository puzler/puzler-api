class AddPuzzles < ActiveRecord::Migration[7.0]
  def change
    create_table :puzzles do |t|
      t.references :user, null: false
      t.integer :visibility, null: false, default: 0
      t.string :title
      t.string :author
      t.integer :size, null: false
      t.text :rules
      t.json :cells, null: false
      t.json :global_constraints, null: false, default: {}
      t.json :local_constraints, null: false, default: {}
      t.json :cosmetics, null: false, default: {}
      t.json :solution, null: true

      t.timestamps
    end
  end
end
