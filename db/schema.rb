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

ActiveRecord::Schema.define(version: 20140605105549) do

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
    t.integer  "designation_id"
  end

  add_index "protected_areas", ["designation_id"], :name => "index_protected_areas_on_designation_id"
  add_index "protected_areas", ["governance_id"], :name => "index_protected_areas_on_governance_id"
  add_index "protected_areas", ["iucn_category_id"], :name => "index_protected_areas_on_iucn_category_id"
  add_index "protected_areas", ["legal_status_id"], :name => "index_protected_areas_on_legal_status_id"
  add_index "protected_areas", ["management_authority_id"], :name => "index_protected_areas_on_management_authority_id"
  add_index "protected_areas", ["no_take_status_id"], :name => "index_protected_areas_on_no_take_status_id"
  add_index "protected_areas", ["wdpa_id"], :name => "index_protected_areas_on_wdpa_id", :unique => true
  add_index "protected_areas", ["wdpa_parent_id"], :name => "index_protected_areas_on_wdpa_parent_id"

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
    t.integer  "country_id"
  end

  add_index "sub_locations", ["country_id"], :name => "index_sub_locations_on_country_id"

  create_table "wdpa_source_june2014", primary_key: "ogc_fid", force: true do |t|
    t.float  "metadataid"
    t.string "data_title", limit: nil
    t.string "resp_party", limit: nil
    t.string "resp_email", limit: nil
    t.string "year",       limit: nil
    t.string "language",   limit: nil
    t.string "char_set",   limit: nil
    t.string "ref_system", limit: nil
    t.string "scale",      limit: nil
    t.string "lineage",    limit: nil
    t.string "citation",   limit: nil
    t.string "disclaimer", limit: nil
  end

  create_table "wdpapoint_june2014", primary_key: "ogc_fid", force: true do |t|
    t.spatial "wkb_geometry", limit: {:srid=>4326, :type=>"multi_point"}
    t.integer "wdpaid"
    t.integer "wdpa_pid"
    t.string  "name",         limit: nil
    t.string  "orig_name",    limit: nil
    t.string  "sub_loc",      limit: nil
    t.string  "desig",        limit: nil
    t.string  "desig_eng",    limit: nil
    t.string  "desig_type",   limit: nil
    t.string  "iucn_cat",     limit: nil
    t.string  "int_crit",     limit: nil
    t.string  "marine",       limit: nil
    t.float   "rep_m_area"
    t.float   "rep_area"
    t.string  "status",       limit: nil
    t.integer "status_yr"
    t.string  "gov_type",     limit: nil
    t.string  "mang_auth",    limit: nil
    t.string  "mang_plan",    limit: nil
    t.string  "no_take",      limit: nil
    t.float   "no_tk_area"
    t.integer "metadataid"
    t.string  "iso3",         limit: nil
    t.string  "parent_iso3",  limit: nil
  end

  add_index "wdpapoint_june2014", ["wkb_geometry"], :name => "wdpapoint_june2014_wkb_geometry_geom_idx", :spatial => true

  create_table "wdpapoly_june2014", primary_key: "ogc_fid", force: true do |t|
    t.spatial "wkb_geometry", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.integer "wdpaid"
    t.integer "wdpa_pid"
    t.string  "name",         limit: nil
    t.string  "orig_name",    limit: nil
    t.string  "sub_loc",      limit: nil
    t.string  "desig",        limit: nil
    t.string  "desig_eng",    limit: nil
    t.string  "desig_type",   limit: nil
    t.string  "iucn_cat",     limit: nil
    t.string  "int_crit",     limit: nil
    t.string  "marine",       limit: nil
    t.float   "rep_m_area"
    t.float   "gis_m_area"
    t.float   "rep_area"
    t.float   "gis_area"
    t.string  "status",       limit: nil
    t.integer "status_yr"
    t.string  "gov_type",     limit: nil
    t.string  "mang_auth",    limit: nil
    t.string  "mang_plan",    limit: nil
    t.string  "no_take",      limit: nil
    t.float   "no_tk_area"
    t.integer "metadataid"
    t.string  "parent_iso3",  limit: nil
    t.string  "iso3",         limit: nil
    t.float   "shape_length"
    t.float   "shape_area"
  end

  add_index "wdpapoly_june2014", ["wkb_geometry"], :name => "wdpapoly_june2014_wkb_geometry_geom_idx", :spatial => true

end
