# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160907083256) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string   "account_num"
    t.string   "account_type"
    t.boolean  "active"
    t.float    "balance"
    t.integer  "user_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["user_id"], name: "index_accounts_on_user_id", using: :btree
  end

  create_table "activities", force: :cascade do |t|
    t.string   "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "activity_logs", force: :cascade do |t|
    t.string   "transaction_code"
    t.integer  "customer_two_id"
    t.boolean  "completed"
    t.integer  "transaction_id"
    t.integer  "user_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["transaction_id"], name: "index_activity_logs_on_transaction_id", using: :btree
    t.index ["user_id"], name: "index_activity_logs_on_user_id", using: :btree
  end

  create_table "atms", force: :cascade do |t|
    t.string   "atm_num"
    t.string   "card_type"
    t.date     "expiry"
    t.integer  "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_atms_on_account_id", using: :btree
  end

  create_table "conversation_contexts", force: :cascade do |t|
    t.string   "key"
    t.text     "dialog_stack",    default: ["root"],              array: true
    t.integer  "turn_counter",    default: 1
    t.integer  "request_counter", default: 1
    t.string   "convo_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.integer  "user_id"
    t.index ["user_id"], name: "index_conversation_contexts_on_user_id", using: :btree
  end

  create_table "login_contexts", force: :cascade do |t|
    t.string   "key"
    t.text     "dialog_stack",    default: ["root"],              array: true
    t.integer  "turn_counter"
    t.integer  "request_counter"
    t.string   "convo_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "otps", force: :cascade do |t|
    t.string   "value"
    t.boolean  "status"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_otps_on_user_id", using: :btree
  end

  create_table "staffs", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "temp_new_users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.integer  "phone"
    t.string   "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "temp_transactions", force: :cascade do |t|
    t.integer  "amount"
    t.integer  "sender_id"
    t.integer  "receiver_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "temp_user_updates", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "email"
    t.string   "address"
    t.string   "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_temp_user_updates_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "firstname"
    t.string   "lastname"
    t.string   "street_address"
    t.string   "city"
    t.string   "state"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "email"
    t.string   "phone"
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "activity_logs", "activities", column: "transaction_id"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "atms", "accounts"
  add_foreign_key "conversation_contexts", "users"
  add_foreign_key "otps", "users"
  add_foreign_key "temp_user_updates", "users"
end
