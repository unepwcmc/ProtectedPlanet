#!/usr/bin/env ruby
# frozen_string_literal: true
# Ad-hoc contract check for portal_standard_* views without invoking Rails test DB setup.
# Usage inside container:
#   RAILS_ENV=development ruby script/check_portal_views_contract.rb
# Usage outside container:
#   docker exec protectedplanet-web bash -lc "RAILS_ENV=development ruby script/check_portal_views_contract.rb"

ENV['RAILS_ENV'] ||= 'development'
require_relative '../config/environment'

conn = ActiveRecord::Base.connection

def assert!(condition, message)
  unless condition
    warn "[FAIL] #{message}"
    exit 1
  end
end

def view_exists?(conn, name)
  if conn.respond_to?(:data_source_exists?)
    conn.data_source_exists?(name)
  else
    # Fallback: check in information_schema and pg_matviews
    !!conn.select_value(<<~SQL)
      SELECT 1 FROM (
        SELECT table_name AS name FROM information_schema.tables WHERE table_schema = ANY (current_schemas(false))
        UNION ALL
        SELECT table_name AS name FROM information_schema.views WHERE table_schema = ANY (current_schemas(false))
        UNION ALL
        SELECT matviewname AS name FROM pg_matviews WHERE schemaname = ANY (current_schemas(false))
      ) s WHERE name = #{conn.quote(name)} LIMIT 1
    SQL
  end
end

def col_names(conn, name)
  conn.columns(name).map(&:name)
end

def col_types(conn, name)
  conn.columns(name).map { |c| [c.name, c.sql_type] }.to_h
end

db_name = (ActiveRecord::Base.connection.respond_to?(:current_database) ? ActiveRecord::Base.connection.current_database : ActiveRecord::Base.connection_config[:database])
puts "Checking portal views contract against DB=#{db_name} (#{ENV['RAILS_ENV']})"

%w[portal_standard_points portal_standard_polygons portal_standard_sources].each do |v|
  assert!(view_exists?(conn, v), "#{v} should exist")
end

polys_cols = col_names(conn, 'portal_standard_polygons')
points_cols = col_names(conn, 'portal_standard_points')
sources_cols = col_names(conn, 'portal_standard_sources')

required = %w[site_id site_pid name_eng name iso3 prnt_iso3 status status_yr iucn_cat desig desig_type realm inlnd_wtrs govsubtype ownsubtype oecm_asmt wkb_geometry]
assert!((required - polys_cols).empty?, "portal_standard_polygons missing: #{(required - polys_cols).join(', ')}")
assert!((required - points_cols).empty?, "portal_standard_points missing: #{(required - points_cols).join(', ')}")

id_variants = %w[id metadataid]
title_variants = %w[title data_title]
assert!((sources_cols & id_variants).any?, "portal_standard_sources should include one of: #{id_variants.join('/')} (found: #{sources_cols.join(', ')})")
assert!((sources_cols & title_variants).any?, "portal_standard_sources should include one of: #{title_variants.join('/')} (found: #{sources_cols.join(', ')})")
assert!(sources_cols.include?('citation'), "portal_standard_sources should include citation")

polys_types = col_types(conn, 'portal_standard_polygons')
points_types = col_types(conn, 'portal_standard_points')

assert!(polys_types['wkb_geometry'].to_s =~ /geometry/i, 'polygons.wkb_geometry should be geometry')
assert!(points_types['wkb_geometry'].to_s =~ /geometry/i, 'points.wkb_geometry should be geometry')

# SRID checks (only if rows exist)
%w[portal_standard_points portal_standard_polygons].each do |v|
  srid = conn.select_value("SELECT ST_SRID(wkb_geometry) FROM #{conn.quote_table_name(v)} WHERE wkb_geometry IS NOT NULL LIMIT 1")
  if srid
    assert!(srid.to_i == 4326, "#{v}.wkb_geometry SRID should be 4326, got #{srid}")
  end
end

# Duplicates by composite natural key
%w[portal_standard_points portal_standard_polygons].each do |v|
dup_count = conn.select_value(<<~SQL).to_i
    SELECT COUNT(*) FROM (
      SELECT site_id, site_pid, COUNT(*) c
      FROM #{conn.quote_table_name(v)}
      GROUP BY 1,2
      HAVING COUNT(*) > 1
    ) d
  SQL
  assert!(dup_count == 0, "#{v} has duplicate (site_id, site_pid)")
end

# site_type presence
%w[portal_standard_points portal_standard_polygons].each do |v|
  vals = conn.select_values("SELECT DISTINCT site_type FROM #{conn.quote_table_name(v)} WHERE site_type IS NOT NULL LIMIT 5")
  assert!(vals.is_a?(Array), "#{v}.site_type should be present when not null")
end

# realm values if present
allowed = %w[Terrestrial Coastal Marine]
%w[portal_standard_points portal_standard_polygons].each do |v|
  vals = conn.select_values("SELECT DISTINCT realm FROM #{conn.quote_table_name(v)} WHERE realm IS NOT NULL LIMIT 100")
  next if vals.empty?
  assert!((vals - allowed).empty?, "#{v}.realm outside #{allowed.inspect}: #{vals.inspect}")
end

puts "All portal views contract checks passed."
