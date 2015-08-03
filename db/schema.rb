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

ActiveRecord::Schema.define(version: 20150803071537) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "annotations", force: :cascade do |t|
    t.integer  "digital_object_id"
    t.integer  "concept_id"
    t.integer  "project_id"
    t.integer  "user_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "annotations", ["concept_id"], name: "index_annotations_on_concept_id", using: :btree
  add_index "annotations", ["digital_object_id"], name: "index_annotations_on_digital_object_id", using: :btree
  add_index "annotations", ["project_id"], name: "index_annotations_on_project_id", using: :btree
  add_index "annotations", ["user_id"], name: "index_annotations_on_user_id", using: :btree

  create_table "concepts", force: :cascade do |t|
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
  end

  add_index "concepts", ["project_id"], name: "index_concepts_on_project_id", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "digital_objects", force: :cascade do |t|
    t.text     "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
    t.string   "thumbnail_url"
  end

  add_index "digital_objects", ["project_id"], name: "index_digital_objects_on_project_id", using: :btree

  create_table "projects", force: :cascade do |t|
    t.text     "notes"
    t.string   "administrator_key"
    t.string   "contributor_key"
    t.string   "viewer_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "algorithm"
  end

  create_table "thumbnails", force: :cascade do |t|
    t.string   "source"
    t.integer  "x"
    t.integer  "y"
    t.string   "url"
    t.boolean  "flipped"
    t.boolean  "local"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "thumbnails", ["source", "x", "y"], name: "index_thumbnails_on_source_and_x_and_y", using: :btree

  create_table "user_roles", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "position"
  end

  add_index "user_roles", ["project_id"], name: "index_user_roles_on_project_id", using: :btree
  add_index "user_roles", ["user_id"], name: "index_user_roles_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  add_foreign_key "annotations", "concepts"
  add_foreign_key "annotations", "digital_objects"
  add_foreign_key "annotations", "projects"
  add_foreign_key "annotations", "users"
end
