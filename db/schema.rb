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

ActiveRecord::Schema[7.0].define(version: 2023_11_08_112217) do
  create_table "activities", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "goal_title"
    t.string "small_goal_title"
    t.integer "exp_gained"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["user_id"], name: "index_goals_on_user_id"
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
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "activities", "users"
  add_foreign_key "goals", "users"
  add_foreign_key "small_goals", "goals"
  add_foreign_key "tasks", "small_goals"
end
