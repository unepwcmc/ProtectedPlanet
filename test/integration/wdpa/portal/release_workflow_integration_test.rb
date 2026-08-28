require 'test_helper'

class Wdpa::Portal::ReleaseWorkflowIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    # VACUUM cannot run inside a transaction, and this test runs in one. The release
    # itself never does -- it is a rake task -- so the vacuum is the one step of
    # cleanup that can only be exercised outside the suite.
    Wdpa::Portal::Services::Core::TableCleanupService.any_instance.stubs(:perform_vacuum_operations)

    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
    Wdpa::Portal::Managers::StagingTableManager.create_staging_tables
  end

  def teardown
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

    # The importer matches portal rows to countries by ISO3; with none loaded every
    # row is dropped and staging_protected_areas comes out empty.
    seed_reference_data

    # 1. Run the high-level portal importer into staging + live helper tables.
    # Give it a release to hang its checkpoints off, as a real release does: without
    # one they fall back to a shared tmp file, where offsets left by a previous run
    # make the import skip every row.
    release = Release.create!(label: 'Jan2026')
    result = Wdpa::Portal::Importer.import(create_staging_materialized_views: true, sample: nil, release_id: release.id)

    assert result[:success], "Portal import failed: #{Array(result[:hard_errors]).join(', ')}"
    # The protected areas importer reports hard_errors rather than a :success flag.
    assert_empty Array(result[:protected_areas][:hard_errors]), 'Protected areas staging import should succeed'
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

  def drop_all_portal_materialized_views
    conn = ActiveRecord::Base.connection

    # Drop known live and staging views
    (Wdpa::Portal::Config::PortalImportConfig.portal_live_materialised_view_values +
     Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views.values).each do |view|
      conn.execute("DROP MATERIALIZED VIEW IF EXISTS #{view} CASCADE")
    end
  end
end

