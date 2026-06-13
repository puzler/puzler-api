# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_13_160001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "collection_puzzles", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.bigint "puzzle_id", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "position"], name: "index_collection_puzzles_on_collection_id_and_position"
    t.index ["collection_id", "puzzle_id"], name: "index_collection_puzzles_on_collection_id_and_puzzle_id", unique: true
    t.index ["collection_id"], name: "index_collection_puzzles_on_collection_id"
    t.index ["puzzle_id"], name: "index_collection_puzzles_on_puzzle_id"
  end

  create_table "collection_solve_times", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.datetime "created_at", null: false
    t.bigint "puzzle_id", null: false
    t.integer "seconds", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["collection_id", "puzzle_id", "user_id"], name: "index_collection_solve_times_unique", unique: true
    t.index ["collection_id"], name: "index_collection_solve_times_on_collection_id"
    t.index ["puzzle_id"], name: "index_collection_solve_times_on_puzzle_id"
    t.index ["user_id"], name: "index_collection_solve_times_on_user_id"
  end

  create_table "collections", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "mode", default: 0, null: false
    t.string "share_token"
    t.boolean "timed", default: false, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["author_id"], name: "index_collections_on_author_id"
    t.index ["mode"], name: "index_collections_on_mode"
    t.index ["share_token"], name: "index_collections_on_share_token", unique: true
    t.index ["visibility"], name: "index_collections_on_visibility"
  end

  create_table "comments", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "parent_id"
    t.bigint "puzzle_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["puzzle_id"], name: "index_comments_on_puzzle_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "constraints", force: :cascade do |t|
    t.string "constraint_type", null: false
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.integer "display_order", default: 0, null: false
    t.bigint "puzzle_id", null: false
    t.datetime "updated_at", null: false
    t.index ["puzzle_id", "constraint_type"], name: "index_constraints_on_puzzle_id_and_constraint_type"
    t.index ["puzzle_id"], name: "index_constraints_on_puzzle_id"
  end

  create_table "cosmetics", force: :cascade do |t|
    t.integer "cosmetic_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.integer "display_order", default: 0, null: false
    t.jsonb "position", default: {}, null: false
    t.bigint "puzzle_id", null: false
    t.jsonb "style", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["puzzle_id"], name: "index_cosmetics_on_puzzle_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "puzzle_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["puzzle_id", "user_id"], name: "index_favorites_on_puzzle_id_and_user_id", unique: true
    t.index ["puzzle_id"], name: "index_favorites_on_puzzle_id"
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "folders", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["author_id", "position"], name: "index_folders_on_author_id_and_position"
    t.index ["author_id"], name: "index_folders_on_author_id"
    t.index ["parent_id"], name: "index_folders_on_parent_id"
  end

  create_table "puzzle_access_grants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "granted_by_id", null: false
    t.bigint "puzzle_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["granted_by_id"], name: "index_puzzle_access_grants_on_granted_by_id"
    t.index ["puzzle_id", "user_id"], name: "index_puzzle_access_grants_on_puzzle_id_and_user_id", unique: true
    t.index ["puzzle_id"], name: "index_puzzle_access_grants_on_puzzle_id"
    t.index ["user_id"], name: "index_puzzle_access_grants_on_user_id"
  end

  create_table "puzzle_plays", force: :cascade do |t|
    t.jsonb "cell_state", default: {}, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.boolean "is_solved", default: false, null: false
    t.bigint "puzzle_id", null: false
    t.datetime "started_at"
    t.integer "time_elapsed_seconds", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["puzzle_id"], name: "index_puzzle_plays_on_puzzle_id"
    t.index ["user_id"], name: "index_puzzle_plays_on_user_id"
  end

  create_table "puzzle_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "puzzle_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["puzzle_id", "tag_id"], name: "index_puzzle_tags_on_puzzle_id_and_tag_id", unique: true
    t.index ["puzzle_id"], name: "index_puzzle_tags_on_puzzle_id"
    t.index ["tag_id"], name: "index_puzzle_tags_on_tag_id"
  end

  create_table "puzzle_versions", force: :cascade do |t|
    t.string "constraint_types", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.jsonb "definition", default: {}, null: false
    t.string "label"
    t.bigint "puzzle_id", null: false
    t.jsonb "solution", default: {}, null: false
    t.string "solution_hash"
    t.text "solve_message"
    t.datetime "updated_at", null: false
    t.integer "version_number", null: false
    t.index ["constraint_types"], name: "index_puzzle_versions_on_constraint_types", using: :gin
    t.index ["puzzle_id", "version_number"], name: "index_puzzle_versions_on_puzzle_id_and_version_number", unique: true
    t.index ["puzzle_id"], name: "index_puzzle_versions_on_puzzle_id"
  end

  create_table "puzzles", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.float "avg_difficulty"
    t.float "avg_rating"
    t.jsonb "box_layout"
    t.string "constraint_types", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "favorite_count", default: 0, null: false
    t.boolean "featured", default: false, null: false
    t.bigint "folder_id"
    t.jsonb "given_digits", default: {}, null: false
    t.integer "grid_cols", default: 9, null: false
    t.integer "grid_rows", default: 9, null: false
    t.string "patreon_campaign_id"
    t.datetime "published_at"
    t.bigint "published_version_id"
    t.jsonb "ruleset", default: {}, null: false
    t.string "share_token"
    t.jsonb "solution", default: {}, null: false
    t.string "solution_hash"
    t.integer "solve_count", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "version_counter", default: 0, null: false
    t.integer "visibility", default: 0, null: false
    t.index ["author_id"], name: "index_puzzles_on_author_id"
    t.index ["constraint_types"], name: "index_puzzles_on_constraint_types", using: :gin
    t.index ["folder_id"], name: "index_puzzles_on_folder_id"
    t.index ["published_at"], name: "index_puzzles_on_published_at"
    t.index ["published_version_id"], name: "index_puzzles_on_published_version_id"
    t.index ["share_token"], name: "index_puzzles_on_share_token", unique: true
    t.index ["solution_hash"], name: "index_puzzles_on_solution_hash"
    t.index ["status"], name: "index_puzzles_on_status"
    t.index ["visibility"], name: "index_puzzles_on_visibility"
  end

  create_table "ratings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "difficulty_vote"
    t.bigint "puzzle_id", null: false
    t.integer "stars"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["puzzle_id", "user_id"], name: "index_ratings_on_puzzle_id_and_user_id", unique: true
    t.index ["puzzle_id"], name: "index_ratings_on_puzzle_id"
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "series", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "share_token", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["author_id"], name: "index_series_on_author_id"
    t.index ["share_token"], name: "index_series_on_share_token", unique: true
    t.index ["visibility"], name: "index_series_on_visibility"
  end

  create_table "series_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "entryable_id", null: false
    t.string "entryable_type", null: false
    t.integer "position", default: 0, null: false
    t.datetime "released_at"
    t.bigint "series_id", null: false
    t.datetime "updated_at", null: false
    t.index ["entryable_type", "entryable_id"], name: "index_series_entries_on_entryable"
    t.index ["released_at"], name: "index_series_entries_on_released_at"
    t.index ["series_id", "entryable_type", "entryable_id"], name: "index_series_entries_unique", unique: true
    t.index ["series_id", "position"], name: "index_series_entries_on_series_id_and_position"
    t.index ["series_id"], name: "index_series_entries_on_series_id"
  end

  create_table "series_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "series_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["series_id", "user_id"], name: "index_series_subscriptions_on_series_id_and_user_id", unique: true
    t.index ["series_id"], name: "index_series_subscriptions_on_series_id"
    t.index ["user_id"], name: "index_series_subscriptions_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "user_oauth_identities", force: :cascade do |t|
    t.text "access_token"
    t.datetime "created_at", null: false
    t.string "provider", null: false
    t.text "refresh_token"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["provider", "uid"], name: "index_user_oauth_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_user_oauth_identities_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "jti", null: false
    t.boolean "password_set", default: true, null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "collection_puzzles", "collections"
  add_foreign_key "collection_puzzles", "puzzles"
  add_foreign_key "collection_solve_times", "collections"
  add_foreign_key "collection_solve_times", "puzzles"
  add_foreign_key "collection_solve_times", "users"
  add_foreign_key "collections", "users", column: "author_id"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "puzzles"
  add_foreign_key "comments", "users"
  add_foreign_key "constraints", "puzzles"
  add_foreign_key "cosmetics", "puzzles"
  add_foreign_key "favorites", "puzzles"
  add_foreign_key "favorites", "users"
  add_foreign_key "folders", "folders", column: "parent_id", on_delete: :nullify
  add_foreign_key "folders", "users", column: "author_id"
  add_foreign_key "puzzle_access_grants", "puzzles"
  add_foreign_key "puzzle_access_grants", "users"
  add_foreign_key "puzzle_access_grants", "users", column: "granted_by_id"
  add_foreign_key "puzzle_plays", "puzzles"
  add_foreign_key "puzzle_plays", "users"
  add_foreign_key "puzzle_tags", "puzzles"
  add_foreign_key "puzzle_tags", "tags"
  add_foreign_key "puzzle_versions", "puzzles"
  add_foreign_key "puzzles", "folders", on_delete: :nullify
  add_foreign_key "puzzles", "puzzle_versions", column: "published_version_id", on_delete: :nullify
  add_foreign_key "puzzles", "users", column: "author_id"
  add_foreign_key "ratings", "puzzles"
  add_foreign_key "ratings", "users"
  add_foreign_key "series", "users", column: "author_id"
  add_foreign_key "series_entries", "series"
  add_foreign_key "series_subscriptions", "series"
  add_foreign_key "series_subscriptions", "users"
  add_foreign_key "user_oauth_identities", "users"
end
