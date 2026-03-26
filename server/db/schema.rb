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

ActiveRecord::Schema[8.1].define(version: 2026_03_26_063925) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "cities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "state", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "state"], name: "index_cities_on_name_and_state", unique: true
  end

  create_table "formats", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_formats_on_code", unique: true
    t.index ["name"], name: "index_formats_on_name", unique: true
  end

  create_table "languages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_languages_on_code", unique: true
    t.index ["name"], name: "index_languages_on_name", unique: true
  end

  create_table "screen_capabilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "format_id", null: false
    t.uuid "screen_id", null: false
    t.datetime "updated_at", null: false
    t.index ["format_id"], name: "index_screen_capabilities_on_format_id"
    t.index ["screen_id", "format_id"], name: "index_screen_capabilities_on_screen_id_and_format_id", unique: true
    t.index ["screen_id"], name: "index_screen_capabilities_on_screen_id"
  end

  create_table "screens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.uuid "theatre_id", null: false
    t.integer "total_columns", null: false
    t.integer "total_rows", null: false
    t.integer "total_seats", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["theatre_id", "name"], name: "index_screens_on_theatre_id_and_name", unique: true
    t.index ["theatre_id"], name: "index_screens_on_theatre_id"
  end

  create_table "theatres", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "building_name"
    t.uuid "city_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "pincode"
    t.string "street_address"
    t.datetime "updated_at", null: false
    t.uuid "vendor_id", null: false
    t.index ["city_id"], name: "index_theatres_on_city_id"
    t.index ["vendor_id"], name: "index_theatres_on_vendor_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "screen_capabilities", "formats"
  add_foreign_key "screen_capabilities", "screens"
  add_foreign_key "screens", "theatres"
  add_foreign_key "theatres", "cities"
  add_foreign_key "theatres", "users", column: "vendor_id"
end
