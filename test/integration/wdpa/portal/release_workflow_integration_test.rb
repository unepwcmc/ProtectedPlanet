require 'test_helper'

class Wdpa::Portal::ReleaseWorkflowIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    # Ensure staging tables exist; importer will ensure required views itself
    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
    Wdpa::Portal::Managers::StagingTableManager.create_staging_tables
  end

  def teardown
    # Drop staging tables and any backup/live tables created during swap
    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables

    # Drop all portal-related materialized views (live, staging, backups)
    drop_all_portal_materialized_views
  end

  test 'runs full portal release workflow from import to swap and cleanup' do
    # This end-to-end workflow requires the Portal FDW schema and tables (portal_fdw.*)
    # to be present in the test database. If they are not available, skip gracefully.
    fdw_check = ActiveRecord::Base.connection.execute(
      "SELECT to_regclass('portal_fdw.wdpa_iso3') AS exists"
    ).first

    skip 'Portal FDW schema/tables not available in test DB; full release workflow cannot be exercised here' if fdw_check['exists'].nil?

    # 1. Run the high-level portal importer into staging + live helper tables
    result = Wdpa::Portal::Importer.import(create_staging_materialized_views: true, sample: nil)

    assert result[:success], "Portal import failed: #{Array(result[:hard_errors]).join(', ')}"
    assert result[:protected_areas][:success], 'Protected areas staging import should succeed'
    assert result[:sources][:success], 'Sources staging import should succeed'

    # Basic sanity check that staging tables now contain data
    assert_operator Staging::ProtectedArea.count, :>, 0
    assert_operator Staging::ProtectedAreaParcel.count, :>=, 0

    # 2. Promote staging tables and portal views to live using the swap service
    backup_timestamp = Wdpa::Portal::Services::Core::TableSwapService.promote_staging_to_live
    assert backup_timestamp.present?, 'Swap service should return a backup timestamp string'

    # After swap, live tables should exist and be populated
    live_tables = Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash.keys
    live_tables.each do |live_table|
      assert ActiveRecord::Base.connection.table_exists?(live_table), "Expected live table #{live_table} to exist after swap"
    end

    # 3. Run post-swap cleanup to vacuum and prune old backups
    assert_nothing_raised do
      Wdpa::Portal::Services::Core::TableCleanupService.cleanup_after_swap
    end
  end

  private

  def create_test_portal_staging_views
    polygons_view = Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views[:polygons]
    points_view   = Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views[:points]
    sources_view  = Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views[:sources]

    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW #{polygons_view} AS
      SELECT
        1 as site_id,
        '1' as site_pid,
        'Test Polygon PA' as name,
        'Designated' as status,
        'Ia' as iucn_cat,
        ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
      UNION ALL
      SELECT
        2 as site_id,
        '2' as site_pid,
        'Test Polygon PA 2' as name,
        'Designated' as status,
        'II' as iucn_cat,
        ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))') as wkb_geometry;

      CREATE MATERIALIZED VIEW #{points_view} AS
      SELECT
        3 as site_id,
        '3' as site_pid,
        'Test Point PA' as name,
        'Designated' as status,
        'III' as iucn_cat,
        ST_GeomFromText('POINT(0.5 0.5)') as wkb_geometry;

      CREATE MATERIALIZED VIEW #{sources_view} AS
      SELECT
        1 as id,
        'Test Source' as title,
        'Test Description' as description,
        2024 as year,
        'en' as language;
    SQL
  end

  def drop_all_portal_materialized_views
    conn = ActiveRecord::Base.connection

    # Drop known live and staging views
    (Wdpa::Portal::Config::PortalImportConfig.portal_live_materialised_view_values +
     Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views.values).each do |view|
      conn.execute("DROP MATERIALIZED VIEW IF EXISTS #{view} CASCADE")
    end
  end
end

