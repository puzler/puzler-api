class AddPasswordSetToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :password_set, :boolean, null: false, default: true

    # Users created through OAuth received a random password they never saw.
    # Best available heuristic: anyone with an OAuth identity gets false.
    execute <<~SQL
      UPDATE users
      SET password_set = FALSE
      WHERE id IN (SELECT DISTINCT user_id FROM user_oauth_identities)
    SQL
  end

  def down
    remove_column :users, :password_set
  end
end
