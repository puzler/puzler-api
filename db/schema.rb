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

ActiveRecord::Schema[7.2].define(version: 2026_05_08_200039) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "comments", force: :cascade do |t|
    t.bigint "puzzle_id", null: false
    t.bigint "user_id", null: false
    t.text "body"
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["puzzle_id"], name: "index_comments_on_puzzle_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "constraints", force: :cascade do |t|
    t.bigint "puzzle_id", null: false
    t.string "constraint_type", null: false
    t.jsonb "data", default: {}, null: false
    t.integer "display_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["puzzle_id", "constraint_type"], name: "index_constraints_on_puzzle_id_and_constraint_type"
    t.index ["puzzle_id"], name: "index_constraints_on_puzzle_id"
  end

  create_table "cosmetics", force: :cascade do |t|
    t.bigint "puzzle_id", null: false
    t.integer "cosmetic_type", default: 0, null: false
    t.jsonb "position", default: {}, null: false
    t.jsonb "style", default: {}, null: false
    t.jsonb "data", default: {}, null: false
    t.integer "display_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["puzzle_id"], name: "index_cosmetics_on_puzzle_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "puzzle_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["puzzle_id", "user_id"], name: "index_favorites_on_puzzle_id_and_user_id", unique: true
    t.index ["puzzle_id"], name: "index_favorites_on_puzzle_id"
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "puzzle_plays", force: :cascade do |t|
    t.bigint "puzzle_id", null: false
    t.bigint "user_id"
    t.jsonb "cell_state", default: {}, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "time_elapsed_seconds", default: 0
    t.boolean "is_solved", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["puzzle_id"], name: "index_puzzle_plays_on_puzzle_id"
    t.index ["user_id"], name: "index_puzzle_plays_on_user_id"
  end

  create_table "puzzle_tags", force: :cascade do |t|
    t.bigint "puzzle_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["puzzle_id", "tag_id"], name: "index_puzzle_tags_on_puzzle_id_and_tag_id", unique: true
    t.index ["puzzle_id"], name: "index_puzzle_tags_on_puzzle_id"
    t.index ["tag_id"], name: "index_puzzle_tags_on_tag_id"
  end

  create_table "puzzles", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "grid_rows", default: 9, null: false
    t.integer "grid_cols", default: 9, null: false
    t.jsonb "box_layout"
    t.jsonb "given_digits", default: {}, null: false
    t.jsonb "solution", default: {}, null: false
    t.string "solution_hash"
    t.jsonb "ruleset", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.datetime "published_at"
    t.float "avg_difficulty"
    t.float "avg_rating"
    t.integer "solve_count", default: 0, null: false
    t.integer "favorite_count", default: 0, null: false
    t.string "patreon_campaign_id"
    t.integer "patron_visibility", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_puzzles_on_author_id"
    t.index ["published_at"], name: "index_puzzles_on_published_at"
    t.index ["solution_hash"], name: "index_puzzles_on_solution_hash"
    t.index ["status"], name: "index_puzzles_on_status"
  end

  create_table "ratings", force: :cascade do |t|
    t.bigint "puzzle_id", null: false
    t.bigint "user_id", null: false
    t.integer "stars"
    t.integer "difficulty_vote"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["puzzle_id", "user_id"], name: "index_ratings_on_puzzle_id_and_user_id", unique: true
    t.index ["puzzle_id"], name: "index_ratings_on_puzzle_id"
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "user_oauth_identities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_user_oauth_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_user_oauth_identities_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "username", null: false
    t.string "avatar_url"
    t.text "bio"
    t.integer "role", default: 0, null: false
    t.string "jti", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "puzzles"
  add_foreign_key "comments", "users"
  add_foreign_key "constraints", "puzzles"
  add_foreign_key "cosmetics", "puzzles"
  add_foreign_key "favorites", "puzzles"
  add_foreign_key "favorites", "users"
  add_foreign_key "puzzle_plays", "puzzles"
  add_foreign_key "puzzle_plays", "users"
  add_foreign_key "puzzle_tags", "puzzles"
  add_foreign_key "puzzle_tags", "tags"
  add_foreign_key "puzzles", "users", column: "author_id"
  add_foreign_key "ratings", "puzzles"
  add_foreign_key "ratings", "users"
  add_foreign_key "user_oauth_identities", "users"
end
