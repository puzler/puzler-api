class AddDisplayNameToUsers < ActiveRecord::Migration[8.0]
  # A free-form, mutable, non-unique name shown to others. `username` stays the
  # unique handle used in profile URLs and lookups. Existing rows seed their
  # display_name from their current username.
  def up
    add_column :users, :display_name, :string
    execute "UPDATE users SET display_name = username WHERE display_name IS NULL"
    change_column_null :users, :display_name, false
  end

  def down
    remove_column :users, :display_name
  end
end
