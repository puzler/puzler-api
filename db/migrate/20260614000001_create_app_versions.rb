class CreateAppVersions < ActiveRecord::Migration[8.0]
  def change
    # Maps each deployed git commit to a sequential version number (the row id).
    # Populated lazily the first time a commit is seen; see AppVersion.
    create_table :app_versions do |t|
      t.string :commit, null: false

      t.timestamps
    end

    add_index :app_versions, :commit, unique: true
  end
end
