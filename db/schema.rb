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

ActiveRecord::Schema[7.0].define(version: 2025_05_30_084740) do
  create_table "activities", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "goal_title"
    t.string "small_goal_title"
    t.integer "exp_gained", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "small_goal_id"
    t.integer "goal_id"
    t.float "exp"
    t.datetime "completed_at"
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "goals", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "content"
    t.string "title"
    t.date "deadline"
    t.string "small_goal"
    t.boolean "completed"
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "jwt_blacklists", charset: "utf8mb3", force: :cascade do |t|
    t.string "jti"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "token"
    t.index ["jti"], name: "index_jwt_blacklists_on_jti", unique: true
    t.index ["token"], name: "index_jwt_blacklists_on_token", unique: true
  end

  create_table "roulette_texts", charset: "utf8mb3", force: :cascade do |t|
    t.integer "number"
    t.string "text"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_roulette_texts_on_user_id"
  end

  create_table "small_goals", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "goal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "title"
    t.string "difficulty"
    t.datetime "deadline"
    t.string "task"
    t.boolean "completed", default: false
    t.datetime "completed_time"
    t.integer "exp"
    t.index ["goal_id"], name: "index_small_goals_on_goal_id"
  end

  create_table "tasks", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "small_goal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "completed", default: false
    t.text "content"
    t.index ["small_goal_id"], name: "index_tasks_on_small_goal_id"
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.integer "exp", default: 0
    t.integer "rank", default: 1
    t.string "remember_digest"
    t.string "activation_digest"
    t.boolean "activated", default: false
    t.datetime "activated_at"
    t.integer "total_exp", default: 0
    t.integer "last_roulette_rank"
    t.integer "tickets", default: 0
    t.integer "title_index", default: 0
    t.string "current_title"
    t.boolean "restart_without_title", default: false
    t.datetime "legendary_hero_obtained_at"
    t.integer "play_tickets", default: 0
    t.integer "edit_tickets", default: 0
    t.string "cognito_sub"
    t.index ["cognito_sub"], name: "index_users_on_cognito_sub", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "activities", "users"
  add_foreign_key "goals", "users"
  add_foreign_key "roulette_texts", "users"
  add_foreign_key "small_goals", "goals"
  add_foreign_key "tasks", "small_goals"
end
