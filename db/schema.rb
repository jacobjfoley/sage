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

ActiveRecord::Schema.define(version: 20150406074841) do

  create_table "concepts", force: :cascade do |t|
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
  end

  add_index "concepts", ["project_id"], name: "index_concepts_on_project_id"

  create_table "concepts_digital_objects", id: false, force: :cascade do |t|
    t.integer "digital_object_id", null: false
    t.integer "concept_id",        null: false
  end

  add_index "concepts_digital_objects", ["concept_id", "digital_object_id"], name: "concept_object"
  add_index "concepts_digital_objects", ["digital_object_id", "concept_id"], name: "object_concept"

  create_table "digital_objects", force: :cascade do |t|
    t.text     "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
  end

  add_index "digital_objects", ["project_id"], name: "index_digital_objects_on_project_id"

  create_table "projects", force: :cascade do |t|
    t.text     "notes"
    t.string   "administrator_key"
    t.string   "contributor_key"
    t.string   "viewer_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  create_table "user_roles", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "position"
  end

  add_index "user_roles", ["project_id"], name: "index_user_roles_on_project_id"
  add_index "user_roles", ["user_id"], name: "index_user_roles_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

end
