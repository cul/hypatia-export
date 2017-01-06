# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20091029185214) do

  create_table "assets", force: :cascade do |t|
    t.integer  "size"
    t.string   "content_type", limit: 255
    t.string   "filename",     limit: 255
    t.integer  "height"
    t.integer  "width"
    t.integer  "parent_id"
    t.string   "thumbnail",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "assets", ["parent_id"], name: "index_assets_on_parent_id"

  create_table "assignments", force: :cascade do |t|
    t.integer "subject_id",               null: false
    t.string  "subject_type", limit: 255, null: false
    t.integer "role_id",                  null: false
  end

  add_index "assignments", ["role_id"], name: "index_assignments_on_role_id"
  add_index "assignments", ["subject_type", "subject_id", "role_id"], name: "by_subject_and_role", unique: true

  create_table "attachments", force: :cascade do |t|
    t.integer "value_id", null: false
    t.integer "asset_id", null: false
  end

  add_index "attachments", ["asset_id"], name: "index_attachments_on_asset_id"
  add_index "attachments", ["value_id"], name: "index_attachments_on_value_id"

  create_table "element_links", force: :cascade do |t|
    t.integer  "child_id",   null: false
    t.integer  "parent_id",  null: false
    t.integer  "position",   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "element_links", ["child_id"], name: "index_element_links_on_child_id"
  add_index "element_links", ["parent_id", "child_id"], name: "index_element_links_on_parent_id_and_child_id", unique: true
  add_index "element_links", ["parent_id", "position"], name: "index_element_links_on_parent_id_and_position", unique: true
  add_index "element_links", ["parent_id"], name: "index_element_links_on_parent_id"

  create_table "elements", force: :cascade do |t|
    t.string   "category",     limit: 255,             null: false
    t.string   "name",         limit: 255,             null: false
    t.string   "code",         limit: 25,              null: false
    t.text     "description"
    t.integer  "minimum",                  default: 1
    t.integer  "maximum",                  default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "field_type",   limit: 20
    t.string   "display_name", limit: 255
  end

  add_index "elements", ["code"], name: "index_elements_on_code"

  create_table "exports", force: :cascade do |t|
    t.integer  "external_store_id", null: false
    t.integer  "item_id",           null: false
    t.integer  "mapping_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "exports", ["item_id"], name: "index_exports_on_item_id"

  create_table "external_stores", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.string   "store_type", limit: 255, null: false
    t.text     "config"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "external_targets", force: :cascade do |t|
    t.integer  "external_store_id",             null: false
    t.string   "target_type",       limit: 255
    t.string   "name",              limit: 255, null: false
    t.string   "value",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "external_targets", ["external_store_id", "target_type"], name: "index_external_targets_on_external_store_id_and_target_type"

  create_table "formats", force: :cascade do |t|
    t.integer "item_type_id", null: false
    t.integer "space_id",     null: false
  end

  create_table "groups", force: :cascade do |t|
    t.string   "name",       limit: 50, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "item_types", force: :cascade do |t|
    t.string   "name",        limit: 60,  null: false
    t.integer  "element_id",              null: false
    t.string   "title_query", limit: 255
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_types", ["element_id"], name: "index_item_types_on_element_id"
  add_index "item_types", ["name"], name: "index_item_types_on_name", unique: true

  create_table "items", force: :cascade do |t|
    t.integer  "item_type_id",             null: false
    t.integer  "space_id"
    t.string   "title",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",       limit: 50
  end

  add_index "items", ["item_type_id"], name: "index_items_on_item_type_id"
  add_index "items", ["space_id", "status"], name: "index_items_on_space_id_and_status"
  add_index "items", ["space_id"], name: "index_items_on_space_id"

  create_table "logs", force: :cascade do |t|
    t.string   "level",          limit: 20
    t.string   "classification", limit: 255, null: false
    t.integer  "loggable_id",                null: false
    t.string   "loggable_type",  limit: 255, null: false
    t.integer  "user_id"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "logs", ["loggable_type", "loggable_id", "classification"], name: "by_loggable_and_classification"

  create_table "mapping_instructions", force: :cascade do |t|
    t.integer  "mapping_id",             null: false
    t.integer  "parent_id"
    t.integer  "position",               null: false
    t.string   "category",   limit: 255, null: false
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mapping_instructions", ["mapping_id", "parent_id", "position"], name: "by_mapping_parent_and_position"

  create_table "mapping_item_types", force: :cascade do |t|
    t.integer  "mapping_id",                           null: false
    t.integer  "item_type_id",                         null: false
    t.string   "code",         limit: 255,             null: false
    t.integer  "minimum",                  default: 1, null: false
    t.integer  "maximum",                  default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mapping_item_types", ["mapping_id", "code"], name: "index_mapping_item_types_on_mapping_id_and_code"
  add_index "mapping_item_types", ["mapping_id", "item_type_id"], name: "index_mapping_item_types_on_mapping_id_and_item_type_id"

  create_table "mapping_templates", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mapping_templates", ["name"], name: "index_mapping_templates_on_name"

  create_table "mappings", force: :cascade do |t|
    t.string   "name",        limit: 255, null: false
    t.text     "description"
    t.string   "store_type",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "user_id",  null: false
    t.integer "group_id", null: false
  end

  create_table "options", force: :cascade do |t|
    t.integer "entity_id"
    t.string  "entity_type", limit: 255
    t.string  "name",        limit: 255, default: "", null: false
    t.text    "value"
  end

  add_index "options", ["entity_type", "entity_id", "name"], name: "by_entity_and_name"

  create_table "permissions", force: :cascade do |t|
    t.integer  "permissible_id",               null: false
    t.string   "permissible_type", limit: 255, null: false
    t.integer  "role_id",                      null: false
    t.text     "action_list"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permissions", ["permissible_id", "permissible_type"], name: "index_permissions_on_permissible_id_and_permissible_type"
  add_index "permissions", ["role_id"], name: "index_permissions_on_role_id"

  create_table "role_links", force: :cascade do |t|
    t.integer "child_id",  null: false
    t.integer "parent_id", null: false
  end

  add_index "role_links", ["child_id"], name: "index_role_links_on_child_id"
  add_index "role_links", ["parent_id"], name: "index_role_links_on_parent_id"

  create_table "roles", force: :cascade do |t|
    t.string   "context_type", limit: 255
    t.string   "context_id",   limit: 255
    t.string   "name",         limit: 20,  null: false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["context_type", "context_id", "name"], name: "index_roles_on_context_type_and_context_id_and_name", unique: true
  add_index "roles", ["context_type", "name"], name: "index_roles_on_context_type_and_name"

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255, null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at"

  create_table "spaces", force: :cascade do |t|
    t.string   "code",                 limit: 35,                 null: false
    t.string   "name",                 limit: 255,                null: false
    t.integer  "workflow_id",                                     null: false
    t.string   "workflow_create_role", limit: 255
    t.text     "description"
    t.boolean  "enabled",                          default: true, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "spaces", ["code"], name: "index_spaces_on_code", unique: true
  add_index "spaces", ["workflow_id"], name: "index_spaces_on_workflow_id"

  create_table "sword_deposits", force: :cascade do |t|
    t.string   "file_name",            limit: 120, null: false
    t.string   "content_type",         limit: 80,  null: false
    t.string   "packaging",            limit: 120, null: false
    t.string   "user",                 limit: 60,  null: false
    t.string   "on_behalf_of",         limit: 60
    t.string   "collection",           limit: 120, null: false
    t.string   "md5_digest",           limit: 100, null: false
    t.datetime "received",                         null: false
    t.datetime "embargo_release_date"
    t.integer  "item_id",              limit: 8
    t.datetime "item_created"
    t.string   "pid_id",               limit: 20
    t.datetime "pid_created"
  end

  add_index "sword_deposits", ["md5_digest"], name: "file_name_index", unique: true

  create_table "swords", force: :cascade do |t|
    t.string   "depositor",    limit: 128
    t.string   "sword_pid",    limit: 32
    t.string   "item_id",      limit: 32
    t.string   "ac_pid",       limit: 32
    t.datetime "received"
    t.datetime "uploaded"
    t.datetime "item_created"
  end

  add_index "swords", ["sword_pid"], name: "sword_pid", unique: true

  create_table "users", force: :cascade do |t|
    t.string   "first_name", limit: 30, null: false
    t.string   "last_name",  limit: 40, null: false
    t.string   "email",      limit: 50, null: false
    t.string   "federation", limit: 12
    t.string   "uid",        limit: 20
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["federation", "uid"], name: "index_users_on_federation_and_uid", unique: true
  add_index "users", ["last_name", "first_name"], name: "index_users_on_last_name_and_first_name"

  create_table "values", force: :cascade do |t|
    t.integer  "item_id",    null: false
    t.integer  "element_id", null: false
    t.integer  "parent_id"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "values", ["item_id", "element_id", "parent_id"], name: "index_values_on_item_id_and_element_id_and_parent_id"

  create_table "verification_sets", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "verification_tests", force: :cascade do |t|
    t.integer  "set_id",                 null: false
    t.integer  "element_id"
    t.string   "category",   limit: 255, null: false
    t.string   "query",      limit: 255
    t.string   "value",      limit: 255
    t.string   "message",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "verification_tests", ["set_id"], name: "index_verification_tests_on_set_id"

  create_table "vocabularies", force: :cascade do |t|
    t.string   "name",        limit: 255, null: false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "vocabulary_members", force: :cascade do |t|
    t.integer "vocabulary_id",                         null: false
    t.integer "parent_id"
    t.string  "name",          limit: 255,             null: false
    t.string  "value",         limit: 255
    t.integer "position",                  default: 0
  end

  create_table "workflows", force: :cascade do |t|
    t.string   "name",       limit: 50, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
