# frozen_string_literal: true

require_relative 'contract_test_helper'

# Contract tests for the Portal FDW materialized views that ProtectedPlanet relies on.
# These tests are intentionally lightweight and schema-focused so CI fails fast
# if the views drift or are missing expected columns/types.
#
# Run with:
#   bundle exec ruby test/contracts/portal_views_contract_test.rb
#
# They connect to pp_development (not pp_test) because the FDW foreign tables
# and materialized views only exist there.
class PortalViewsContractTest < ActiveSupport::TestCase
  def conn
    ActiveRecord::Base.connection
  end

  # Use a direct pg_matviews query instead of table_exists? — Rails 5.2's
  # table_exists? only checks regular tables, not materialized views.
  def assert_view_exists(view_name)
    exists = conn.select_value(
      "SELECT 1 FROM pg_matviews WHERE schemaname = 'public' AND matviewname = #{conn.quote(view_name)}"
    ).present?
    assert exists, "Expected materialized view '#{view_name}' to exist, but it was not found.\n" \
      "Make sure FDW_VIEWS.sql has been applied to pp_development before running these tests."
  end

  def column_names(view_name)
    conn.columns(view_name).map(&:name)
  end

  def column_types(view_name)
    conn.columns(view_name).map { |c| [c.name, c.sql_type] }.to_h
  end

  # Columns that both portal_standard_points and portal_standard_polygons must have.
  def expected_wdpa_cols
    %w[site_id site_pid name_eng name iso3 prnt_iso3 status status_yr iucn_cat
       desig desig_type realm inlnd_wtrs govsubtype ownsubtype oecm_asmt wkb_geometry]
  end

  # ---------------------------------------------------------------------------
  # portal_standard_polygons (legacy WDPA MV)
  # ---------------------------------------------------------------------------

  test 'portal_standard_polygons has required columns' do
    assert_view_exists 'portal_standard_polygons'
    cols = column_names('portal_standard_polygons')
    missing = expected_wdpa_cols - cols
    assert missing.empty?,
      "Missing columns on portal_standard_polygons: #{missing.join(', ')}. Found: #{cols.sort.join(', ')}"
  end

  test 'key types look correct on portal_standard_polygons' do
    assert_view_exists 'portal_standard_polygons'
    types = column_types('portal_standard_polygons')

    # site_id is stored as double precision in this legacy MV
    assert_match(/double precision/i, types['site_id'].to_s,  'site_id should be double precision')
    assert_match(/character varying/i, types['site_pid'].to_s, 'site_pid should be character varying')
    assert_match(/integer/i,           types['status_yr'].to_s, 'status_yr should be integer')
    assert_match(/geometry/i,          types['wkb_geometry'].to_s, 'wkb_geometry should be geometry')
  end

  # ---------------------------------------------------------------------------
  # portal_standard_points (legacy WDPA MV)
  # ---------------------------------------------------------------------------

  test 'portal_standard_points has required columns' do
    assert_view_exists 'portal_standard_points'
    cols = column_names('portal_standard_points')
    missing = expected_wdpa_cols - cols
    assert missing.empty?,
      "Missing columns on portal_standard_points: #{missing.join(', ')}. Found: #{cols.sort.join(', ')}"
  end

  test 'key types look correct on portal_standard_points' do
    assert_view_exists 'portal_standard_points'
    types = column_types('portal_standard_points')

    # site_id is stored as double precision in this legacy MV
    assert_match(/double precision/i, types['site_id'].to_s,  'site_id should be double precision')
    assert_match(/character varying/i, types['site_pid'].to_s, 'site_pid should be character varying')
    assert_match(/integer/i,           types['status_yr'].to_s, 'status_yr should be integer')
    assert_match(/geometry/i,          types['wkb_geometry'].to_s, 'wkb_geometry should be geometry')
  end

  # ---------------------------------------------------------------------------
  # portal_standard_sources (legacy WDPA MV)
  # ---------------------------------------------------------------------------

  test 'portal_standard_sources has required columns' do
    assert_view_exists 'portal_standard_sources'
    cols = column_names('portal_standard_sources')

    id_variants    = %w[id metadataid]
    title_variants = %w[title data_title]

    assert !(cols & id_variants).empty?,
      "Expected one of #{id_variants.join('/')} on portal_standard_sources, got: #{cols.sort.join(', ')}"
    assert !(cols & title_variants).empty?,
      "Expected one of #{title_variants.join('/')} on portal_standard_sources, got: #{cols.sort.join(', ')}"
    assert_includes cols, 'citation', "Expected 'citation' column on portal_standard_sources"
  end

  # ---------------------------------------------------------------------------
  # Shared geometry / uniqueness / domain checks (legacy WDPA MVs)
  # ---------------------------------------------------------------------------

  test 'geometry SRID is 4326 when sample rows exist' do
    %w[portal_standard_points portal_standard_polygons].each do |view|
      assert_view_exists view
      srid = conn.select_value(<<~SQL)
        SELECT ST_SRID(wkb_geometry)
        FROM #{conn.quote_table_name(view)}
        WHERE wkb_geometry IS NOT NULL
        LIMIT 1
      SQL
      assert_equal 4326, srid.to_i, "Expected SRID 4326 for #{view}.wkb_geometry, got #{srid}" if srid.present?
    end
  end

  test 'no duplicates on composite natural key (site_id, site_pid) for legacy WDPA MVs' do
    %w[portal_standard_points portal_standard_polygons].each do |view|
      assert_view_exists view
      dup_count = conn.select_value(<<~SQL).to_i
        SELECT COUNT(*) FROM (
          SELECT site_id, site_pid, COUNT(*) c
          FROM #{conn.quote_table_name(view)}
          GROUP BY 1, 2
          HAVING COUNT(*) > 1
        ) d
      SQL
      assert_equal 0, dup_count, "Found duplicate rows on #{view} by (site_id, site_pid)"
    end
  end

  test 'realm values (if present) come from known realm codes' do
    %w[portal_standard_points portal_standard_polygons].each do |view|
      assert_view_exists view
      vals = conn.select_values(<<~SQL).compact
        SELECT DISTINCT realm FROM #{conn.quote_table_name(view)}
        WHERE realm IS NOT NULL LIMIT 100
      SQL
      next if vals.empty?
      allowed    = %w[Terrestrial Coastal Marine]
      unexpected = vals - allowed
      assert unexpected.empty?,
        "#{view}.realm contains values outside #{allowed.inspect}: #{unexpected.inspect}"
    end
  end

  # ---------------------------------------------------------------------------
  # staging_portal_standard_pame_sources
  # ---------------------------------------------------------------------------

  test 'staging_portal_standard_pame_sources has required columns' do
    assert_view_exists 'staging_portal_standard_pame_sources'
    cols    = column_names('staging_portal_standard_pame_sources')
    expected = %w[eff_metaid data_title resp_party resp_email resp_pers year language]
    missing  = expected - cols
    assert missing.empty?,
      "Missing columns on staging_portal_standard_pame_sources: #{missing.join(', ')}. Found: #{cols.sort.join(', ')}"
  end

  test 'key types look correct on staging_portal_standard_pame_sources' do
    assert_view_exists 'staging_portal_standard_pame_sources'
    types = column_types('staging_portal_standard_pame_sources')

    assert_match(/bigint/i,  types['id'].to_s,         'id should be bigint')
    assert_match(/bigint/i,  types['eff_metaid'].to_s,  'eff_metaid should be bigint')
    assert_match(/integer/i, types['year'].to_s,        'year should be integer')
  end

  test 'no duplicate ids on staging_portal_standard_pame_sources' do
    assert_view_exists 'staging_portal_standard_pame_sources'
    dup_count = conn.select_value(<<~SQL).to_i
      SELECT COUNT(*) FROM (
        SELECT id, COUNT(*) c
        FROM staging_portal_standard_pame_sources
        GROUP BY id HAVING COUNT(*) > 1
      ) d
    SQL
    assert_equal 0, dup_count, 'Found duplicate id values in staging_portal_standard_pame_sources'
  end

  # ---------------------------------------------------------------------------
  # staging_portal_standard_pame
  # ---------------------------------------------------------------------------

  test 'staging_portal_standard_pame has required columns' do
    assert_view_exists 'staging_portal_standard_pame'
    cols    = column_names('staging_portal_standard_pame')
    expected = %w[asmt_id eff_metaid site_id site_pid method submityear asmt_year
                  verif_eff asmt_url info_url gov_act gov_asmt dp_bio dp_other
                  mgmt_obset mgmt_obman mgmt_adapt mgmt_staff mgmt_budgt
                  mgmt_thrts mgmt_mon out_bio]
    missing  = expected - cols
    assert missing.empty?,
      "Missing columns on staging_portal_standard_pame: #{missing.join(', ')}. Found: #{cols.sort.join(', ')}"
  end

  test 'key types look correct on staging_portal_standard_pame' do
    assert_view_exists 'staging_portal_standard_pame'
    types = column_types('staging_portal_standard_pame')

    assert_match(/bigint/i,  types['id'].to_s,         'id should be bigint')
    assert_match(/bigint/i,  types['asmt_id'].to_s,    'asmt_id should be bigint')
    assert_match(/bigint/i,  types['eff_metaid'].to_s,  'eff_metaid should be bigint')
    assert_match(/bigint/i,  types['site_id'].to_s,    'site_id should be bigint')
    assert_match(/integer/i, types['asmt_year'].to_s,  'asmt_year should be integer')
  end

  test 'no duplicate ids on staging_portal_standard_pame' do
    assert_view_exists 'staging_portal_standard_pame'
    dup_count = conn.select_value(<<~SQL).to_i
      SELECT COUNT(*) FROM (
        SELECT id, COUNT(*) c
        FROM staging_portal_standard_pame
        GROUP BY id HAVING COUNT(*) > 1
      ) d
    SQL
    assert_equal 0, dup_count, 'Found duplicate id values in staging_portal_standard_pame'
  end

  test 'every pame row references a known pame_source via eff_metaid' do
    assert_view_exists 'staging_portal_standard_pame'
    assert_view_exists 'staging_portal_standard_pame_sources'
    orphan_count = conn.select_value(<<~SQL).to_i
      SELECT COUNT(*) FROM staging_portal_standard_pame p
      WHERE NOT EXISTS (
        SELECT 1 FROM staging_portal_standard_pame_sources s
        WHERE s.eff_metaid = p.eff_metaid
      )
    SQL
    assert_equal 0, orphan_count,
      "Found #{orphan_count} pame rows with no matching pame_source (via eff_metaid)"
  end

  # ---------------------------------------------------------------------------
  # staging_portal_standard_greenlist
  # ---------------------------------------------------------------------------

  test 'staging_portal_standard_greenlist has required columns' do
    assert_view_exists 'staging_portal_standard_greenlist'
    cols    = column_names('staging_portal_standard_greenlist')
    expected = %w[site_id site_pid gl_status gl_expiry gl_link]
    missing  = expected - cols
    assert missing.empty?,
      "Missing columns on staging_portal_standard_greenlist: #{missing.join(', ')}. Found: #{cols.sort.join(', ')}"
  end

  test 'key types look correct on staging_portal_standard_greenlist' do
    assert_view_exists 'staging_portal_standard_greenlist'
    types = column_types('staging_portal_standard_greenlist')

    assert_match(/bigint/i,  types['id'].to_s,        'id should be bigint')
    assert_match(/bigint/i,  types['site_id'].to_s,   'site_id should be bigint')
    assert_match(/integer/i, types['gl_expiry'].to_s, 'gl_expiry should be integer')
  end

  test 'no duplicate ids on staging_portal_standard_greenlist' do
    assert_view_exists 'staging_portal_standard_greenlist'
    dup_count = conn.select_value(<<~SQL).to_i
      SELECT COUNT(*) FROM (
        SELECT id, COUNT(*) c
        FROM staging_portal_standard_greenlist
        GROUP BY id HAVING COUNT(*) > 1
      ) d
    SQL
    assert_equal 0, dup_count, 'Found duplicate id values in staging_portal_standard_greenlist'
  end

  test 'gl_status values come from known Green List status codes' do
    assert_view_exists 'staging_portal_standard_greenlist'
    vals = conn.select_values(<<~SQL).compact
      SELECT DISTINCT gl_status FROM staging_portal_standard_greenlist
      WHERE gl_status IS NOT NULL LIMIT 100
    SQL
    return if vals.empty?
    allowed    = ['Green Listed', 'Candidate', 'Re-Listed', 'Not Applicable']
    unexpected = vals - allowed
    assert unexpected.empty?,
      "staging_portal_standard_greenlist.gl_status contains unknown values outside " \
      "#{allowed.inspect}: #{unexpected.inspect}"
  end
end
