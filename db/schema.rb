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

ActiveRecord::Schema[8.1].define(version: 2025_12_03_111349) do
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

  create_table "adjustments", force: :cascade do |t|
    t.bigint "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD"
    t.bigint "dispute_id", null: false
    t.string "reason"
    t.datetime "updated_at", null: false
    t.index ["dispute_id"], name: "index_adjustments_on_dispute_id"
  end

  create_table "case_actions", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id", null: false
    t.string "actor_type", null: false
    t.datetime "created_at", null: false
    t.jsonb "details", default: {}
    t.bigint "dispute_id", null: false
    t.text "note"
    t.datetime "updated_at", null: false
    t.index ["actor_type", "actor_id"], name: "index_case_actions_on_actor"
    t.index ["dispute_id", "created_at"], name: "index_case_actions_on_dispute_id_and_created_at"
    t.index ["dispute_id"], name: "index_case_actions_on_dispute_id"
  end

  create_table "charges", force: :cascade do |t|
    t.bigint "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD"
    t.string "external_id", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_charges_on_external_id", unique: true
  end

  create_table "disputes", force: :cascade do |t|
    t.bigint "amount_cents"
    t.bigint "charge_id", null: false
    t.datetime "closed_at", precision: nil
    t.datetime "created_at", null: false
    t.string "currency", default: "USD"
    t.string "external_id", null: false
    t.jsonb "external_payload", default: {}, null: false
    t.string "last_event_id"
    t.datetime "opened_at", precision: nil
    t.string "status", default: "needs_response"
    t.datetime "updated_at", null: false
    t.index ["charge_id"], name: "index_disputes_on_charge_id"
    t.index ["external_id"], name: "index_disputes_on_external_id", unique: true
    t.index ["last_event_id"], name: "index_disputes_on_last_event_id"
    t.index ["status"], name: "index_disputes_on_status"
  end

  create_table "evidences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dispute_id", null: false
    t.string "kind"
    t.jsonb "metadata", default: {}
    t.datetime "updated_at", null: false
    t.index ["dispute_id"], name: "index_evidences_on_dispute_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "read_only", null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "adjustments", "disputes"
  add_foreign_key "case_actions", "disputes"
  add_foreign_key "disputes", "charges"
  add_foreign_key "evidences", "disputes"
end
