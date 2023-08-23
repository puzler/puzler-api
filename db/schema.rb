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

ActiveRecord::Schema[7.0].define(version: 2023_08_17_184808) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "csrf_tokens", force: :cascade do |t|
    t.string "client_token_id", null: false
    t.string "token", null: false
    t.datetime "exp", null: false
    t.integer "token_type", null: false
    t.index ["token"], name: "index_csrf_tokens_on_token", unique: true
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti", unique: true
  end

  create_table "puzzles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "visibility", default: 0, null: false
    t.string "title"
    t.string "author"
    t.integer "size", null: false
    t.text "rules"
    t.json "cells", null: false
    t.json "global_constraints", default: {}, null: false
    t.json "local_constraints", default: {}, null: false
    t.json "cosmetics", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_puzzles_on_user_id"
  end

  create_table "user_o_auth_providers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "oauth_id", null: false
    t.integer "provider", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "oauth_id"], name: "index_user_o_auth_providers_on_provider_and_oauth_id", unique: true
    t.index ["user_id", "provider"], name: "index_user_o_auth_providers_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_user_o_auth_providers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "display_name", null: false
    t.string "jwt_salt", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["display_name"], name: "index_users_on_display_name", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jwt_salt"], name: "index_users_on_jwt_salt", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
