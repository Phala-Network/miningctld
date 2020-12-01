# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_11_22_171026) do

  create_table "registered_daemons", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "hash_id"
    t.string "uuid"
    t.integer "role", default: 0
    t.integer "management_status", default: 0
    t.text "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.json "account"
    t.index ["hash_id", "uuid"], name: "index_registered_daemons_on_hash_id_and_uuid"
    t.index ["hash_id"], name: "index_registered_daemons_on_hash_id"
    t.index ["uuid"], name: "index_registered_daemons_on_uuid"
  end

end
