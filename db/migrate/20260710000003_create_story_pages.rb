# Narrative interludes that interleave with puzzles inside a collection (via
# polymorphic collection_entries). Author-owned directly so authorization and
# reuse don't have to route through a collection.
class CreateStoryPages < ActiveRecord::Migration[8.0]
  def change
    create_table :story_pages do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title
      t.text :body_html

      t.timestamps
    end
  end
end
