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

ActiveRecord::Schema[8.1].define(version: 2026_03_31_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "booking_time", null: false
    t.uuid "coupon_id"
    t.datetime "created_at", null: false
    t.string "lock_token"
    t.uuid "show_id", null: false
    t.string "status", default: "pending", null: false
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["coupon_id"], name: "index_bookings_on_coupon_id"
    t.index ["lock_token"], name: "index_bookings_on_lock_token"
    t.index ["show_id", "status"], name: "index_bookings_on_show_id_and_status"
    t.index ["show_id"], name: "index_bookings_on_show_id"
    t.index ["user_id", "booking_time"], name: "index_bookings_on_user_id_and_booking_time"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "cast_members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "character_name"
    t.datetime "created_at", null: false
    t.uuid "movie_id", null: false
    t.string "name", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["movie_id"], name: "index_cast_members_on_movie_id"
  end

  create_table "cities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "state", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "state"], name: "index_cities_on_name_and_state", unique: true
  end

  create_table "coupons", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.string "coupon_type", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "discount_amount", precision: 10, scale: 2
    t.decimal "discount_percentage", precision: 5, scale: 2
    t.integer "max_total_uses"
    t.integer "max_uses_per_user"
    t.decimal "minimum_booking_amount", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.datetime "valid_from", null: false
    t.datetime "valid_until", null: false
    t.index ["code"], name: "index_coupons_on_code", unique: true
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

  create_table "movie_formats", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "format_id", null: false
    t.uuid "movie_id", null: false
    t.datetime "updated_at", null: false
    t.index ["format_id"], name: "index_movie_formats_on_format_id"
    t.index ["movie_id", "format_id"], name: "index_movie_formats_on_movie_id_and_format_id", unique: true
    t.index ["movie_id"], name: "index_movie_formats_on_movie_id"
  end

  create_table "movie_languages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "language_id", null: false
    t.string "language_type", null: false
    t.uuid "movie_id", null: false
    t.datetime "updated_at", null: false
    t.index ["language_id"], name: "index_movie_languages_on_language_id"
    t.index ["movie_id", "language_id"], name: "index_movie_languages_on_movie_id_and_language_id", unique: true
    t.index ["movie_id"], name: "index_movie_languages_on_movie_id"
  end

  create_table "movies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "director"
    t.string "genre", null: false
    t.string "rating", null: false
    t.date "release_date"
    t.integer "running_time"
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payment_refunds", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.uuid "payment_id", null: false
    t.datetime "refunded_at"
    t.string "status", default: "pending", null: false
    t.uuid "ticket_id", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id", "ticket_id"], name: "index_payment_refunds_on_payment_id_and_ticket_id"
    t.index ["payment_id"], name: "index_payment_refunds_on_payment_id"
    t.index ["ticket_id", "status"], name: "index_payment_refunds_on_ticket_id_and_status"
    t.index ["ticket_id"], name: "index_payment_refunds_on_ticket_id"
  end

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.uuid "booking_id", null: false
    t.datetime "created_at", null: false
    t.datetime "paid_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["booking_id"], name: "index_payments_on_booking_id"
    t.index ["user_id", "status"], name: "index_payments_on_user_id_and_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "reviews", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.uuid "movie_id", null: false
    t.decimal "rating", precision: 2, scale: 1, null: false
    t.date "reviewed_on", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["movie_id", "user_id"], name: "index_reviews_on_movie_id_and_user_id", unique: true
    t.index ["movie_id"], name: "index_reviews_on_movie_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
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

  create_table "seat_layouts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "legend_json", default: {}, null: false
    t.string "name", null: false
    t.datetime "published_at"
    t.uuid "screen_id", null: false
    t.string "screen_label"
    t.string "status", default: "draft", null: false
    t.integer "total_columns", null: false
    t.integer "total_rows", null: false
    t.integer "total_seats", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "version_number", null: false
    t.index ["screen_id", "status"], name: "index_seat_layouts_on_screen_id_and_status"
    t.index ["screen_id", "version_number"], name: "index_seat_layouts_on_screen_id_and_version_number", unique: true
    t.index ["screen_id"], name: "index_seat_layouts_on_screen_id"
    t.index ["screen_id"], name: "index_seat_layouts_one_published_per_screen", unique: true, where: "((status)::text = 'published'::text)"
  end

  create_table "seat_sections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.string "color_hex"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "rank", default: 0, null: false
    t.uuid "seat_layout_id", null: false
    t.string "seat_type"
    t.datetime "updated_at", null: false
    t.index ["seat_layout_id", "code"], name: "index_seat_sections_on_seat_layout_id_and_code", unique: true
    t.index ["seat_layout_id", "rank"], name: "index_seat_sections_on_seat_layout_id_and_rank", unique: true
    t.index ["seat_layout_id"], name: "index_seat_sections_on_seat_layout_id"
  end

  create_table "seats", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "grid_column", null: false
    t.integer "grid_row", null: false
    t.boolean "is_accessible", default: false, null: false
    t.boolean "is_active", default: true, null: false
    t.string "label", null: false
    t.string "row_label", null: false
    t.string "seat_kind", default: "standard", null: false
    t.uuid "seat_layout_id", null: false
    t.integer "seat_number", null: false
    t.uuid "seat_section_id", null: false
    t.datetime "updated_at", null: false
    t.integer "x_span", default: 1, null: false
    t.integer "y_span", default: 1, null: false
    t.index ["seat_layout_id", "grid_row", "grid_column"], name: "index_seats_on_seat_layout_id_and_grid_row_and_grid_column", unique: true
    t.index ["seat_layout_id", "label"], name: "index_seats_on_seat_layout_id_and_label", unique: true
    t.index ["seat_layout_id", "seat_section_id"], name: "index_seats_on_seat_layout_id_and_seat_section_id"
  end

  create_table "show_seat_states", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "booking_id"
    t.datetime "created_at", null: false
    t.string "lock_token"
    t.uuid "locked_by_user_id"
    t.datetime "locked_until"
    t.uuid "seat_id", null: false
    t.uuid "show_id", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_show_seat_states_on_booking_id"
    t.index ["lock_token"], name: "index_show_seat_states_on_lock_token"
    t.index ["locked_by_user_id"], name: "index_show_seat_states_on_locked_by_user_id"
    t.index ["seat_id"], name: "index_show_seat_states_on_seat_id"
    t.index ["show_id", "seat_id"], name: "index_show_seat_states_on_show_id_and_seat_id", unique: true
    t.index ["show_id", "status"], name: "index_show_seat_states_on_show_id_and_status"
    t.index ["show_id"], name: "index_show_seat_states_on_show_id"
  end

  create_table "show_section_prices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "base_price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.uuid "seat_section_id", null: false
    t.uuid "show_id", null: false
    t.datetime "updated_at", null: false
    t.index ["seat_section_id"], name: "index_show_section_prices_on_seat_section_id"
    t.index ["show_id", "seat_section_id"], name: "index_show_section_prices_on_show_id_and_seat_section_id", unique: true
    t.index ["show_id"], name: "index_show_section_prices_on_show_id"
  end

  create_table "shows", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "end_time", null: false
    t.uuid "movie_format_id", null: false
    t.uuid "movie_id", null: false
    t.uuid "movie_language_id", null: false
    t.uuid "screen_id", null: false
    t.uuid "seat_layout_id", null: false
    t.datetime "start_time", null: false
    t.string "status", default: "scheduled", null: false
    t.integer "total_capacity", null: false
    t.datetime "updated_at", null: false
    t.index ["movie_format_id"], name: "index_shows_on_movie_format_id"
    t.index ["movie_id"], name: "index_shows_on_movie_id"
    t.index ["movie_language_id"], name: "index_shows_on_movie_language_id"
    t.index ["screen_id", "start_time"], name: "index_shows_on_screen_id_and_start_time"
    t.index ["screen_id", "status", "start_time"], name: "index_shows_on_screen_id_and_status_and_start_time"
    t.index ["screen_id"], name: "index_shows_on_screen_id"
    t.index ["seat_layout_id"], name: "index_shows_on_seat_layout_id"
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

  create_table "tickets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "booking_id", null: false
    t.datetime "created_at", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.uuid "seat_id", null: false
    t.string "seat_label", null: false
    t.string "section_name", null: false
    t.uuid "show_id", null: false
    t.string "status", default: "valid", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id", "status"], name: "index_tickets_on_booking_id_and_status"
    t.index ["booking_id"], name: "index_tickets_on_booking_id"
    t.index ["seat_id"], name: "index_tickets_on_seat_id"
    t.index ["show_id", "seat_id"], name: "index_tickets_on_show_id_and_seat_id", unique: true
    t.index ["show_id"], name: "index_tickets_on_show_id"
  end

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "method", null: false
    t.uuid "payment_id", null: false
    t.string "ref_no", null: false
    t.string "status", default: "pending", null: false
    t.datetime "transaction_time", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id", "status"], name: "index_transactions_on_payment_id_and_status"
    t.index ["payment_id"], name: "index_transactions_on_payment_id"
    t.index ["ref_no"], name: "index_transactions_on_ref_no", unique: true
  end

  create_table "user_coupon_usages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "booking_id", null: false
    t.uuid "coupon_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at", null: false
    t.uuid "user_id", null: false
    t.index ["booking_id"], name: "index_user_coupon_usages_on_booking_id", unique: true
    t.index ["coupon_id", "user_id"], name: "index_user_coupon_usages_on_coupon_id_and_user_id"
    t.index ["coupon_id"], name: "index_user_coupon_usages_on_coupon_id"
    t.index ["user_id"], name: "index_user_coupon_usages_on_user_id"
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

  add_foreign_key "bookings", "coupons"
  add_foreign_key "bookings", "shows"
  add_foreign_key "bookings", "users"
  add_foreign_key "cast_members", "movies"
  add_foreign_key "movie_formats", "formats"
  add_foreign_key "movie_formats", "movies"
  add_foreign_key "movie_languages", "languages"
  add_foreign_key "movie_languages", "movies"
  add_foreign_key "payment_refunds", "payments"
  add_foreign_key "payment_refunds", "tickets"
  add_foreign_key "payments", "bookings"
  add_foreign_key "payments", "users"
  add_foreign_key "reviews", "movies"
  add_foreign_key "reviews", "users"
  add_foreign_key "screen_capabilities", "formats"
  add_foreign_key "screen_capabilities", "screens"
  add_foreign_key "screens", "theatres"
  add_foreign_key "seat_layouts", "screens"
  add_foreign_key "seat_sections", "seat_layouts"
  add_foreign_key "seats", "seat_layouts"
  add_foreign_key "seats", "seat_sections"
  add_foreign_key "show_seat_states", "bookings"
  add_foreign_key "show_seat_states", "seats"
  add_foreign_key "show_seat_states", "shows"
  add_foreign_key "show_seat_states", "users", column: "locked_by_user_id"
  add_foreign_key "show_section_prices", "seat_sections"
  add_foreign_key "show_section_prices", "shows"
  add_foreign_key "shows", "movie_formats"
  add_foreign_key "shows", "movie_languages"
  add_foreign_key "shows", "movies"
  add_foreign_key "shows", "screens"
  add_foreign_key "shows", "seat_layouts"
  add_foreign_key "theatres", "cities"
  add_foreign_key "theatres", "users", column: "vendor_id"
  add_foreign_key "tickets", "bookings"
  add_foreign_key "tickets", "seats"
  add_foreign_key "tickets", "shows"
  add_foreign_key "transactions", "payments"
  add_foreign_key "user_coupon_usages", "bookings"
  add_foreign_key "user_coupon_usages", "coupons"
  add_foreign_key "user_coupon_usages", "users"
end
