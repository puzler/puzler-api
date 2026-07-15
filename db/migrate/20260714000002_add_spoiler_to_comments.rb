class AddSpoilerToComments < ActiveRecord::Migration[8.0]
  def up
    add_column :comments, :spoiler, :boolean, null: false, default: false
    add_reference :comments, :spoiler_marked_by, foreign_key: { to_table: :users }, index: true

    # Bodies written before the ||spoiler|| syntax existed would retroactively
    # gain hidden sections; there should be none, but fail loudly if any exist.
    count = select_value("SELECT COUNT(*) FROM comments WHERE body LIKE '%||%'").to_i
    raise "#{count} existing comments contain '||'; escape them before deploying spoilers" if count.positive?
  end

  def down
    remove_reference :comments, :spoiler_marked_by
    remove_column :comments, :spoiler
  end
end
