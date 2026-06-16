class AddFolderToCollections < ActiveRecord::Migration[8.1]
  def change
    add_reference :collections, :folder, foreign_key: true, null: true, index: true
  end
end
