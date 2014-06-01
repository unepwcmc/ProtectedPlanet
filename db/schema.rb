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

ActiveRecord::Schema.define(version: 20140601211052) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "countries", force: true do |t|
    t.text     "name"
    t.string   "iso"
    t.string   "iso_3"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "countries_protected_areas", id: false, force: true do |t|
    t.integer "protected_area_id"
    t.integer "country_id"
  end

  add_index "countries_protected_areas", ["country_id"], :name => "index_countries_protected_areas_on_country_id"
  add_index "countries_protected_areas", ["protected_area_id", "country_id"], :name => "index_countries_protected_areas_composite"

  create_table "designations", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "jurisdiction_id"
  end

  add_index "designations", ["jurisdiction_id"], :name => "index_designations_on_jurisdiction_id"

  create_table "governances", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "iucn_categories", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "jurisdictions", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "legal_statuses", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "management_authorities", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "no_take_statuses", force: true do |t|
    t.string   "name"
    t.decimal  "area"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "protected_areas", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "the_geom",                limit: {:srid=>0, :type=>"geometry"}
    t.integer  "wdpa_id"
    t.integer  "wdpa_parent_id"
    t.text     "name"
    t.text     "original_name"
    t.boolean  "marine"
    t.decimal  "reported_marine_area"
    t.decimal  "reported_area"
    t.decimal  "gis_area"
    t.decimal  "gis_marine_area"
    t.integer  "legal_status_id"
    t.datetime "legal_status_updated_at"
    t.integer  "iucn_category_id"
    t.integer  "governance_id"
    t.text     "management_plan"
    t.integer  "management_authority_id"
    t.string   "international_criteria"
    t.integer  "no_take_status_id"
  end

  add_index "protected_areas", ["wdpa_id"], :name => "index_protected_areas_on_wdpa_id", :unique => true
  add_index "protected_areas", ["wdpa_parent_id"], :name => "index_protected_areas_on_wdpa_parent_id", :unique => true

  create_table "protected_areas_sub_locations", id: false, force: true do |t|
    t.integer "protected_area_id"
    t.integer "sub_location_id"
  end

  add_index "protected_areas_sub_locations", ["protected_area_id", "sub_location_id"], :name => "index_protected_areas_sub_locations_composite"
  add_index "protected_areas_sub_locations", ["sub_location_id"], :name => "index_protected_areas_sub_locations_on_sub_location_id"

  create_table "sub_locations", force: true do |t|
    t.string   "english_name"
    t.string   "local_name"
    t.string   "alternate_name"
    t.string   "iso"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
