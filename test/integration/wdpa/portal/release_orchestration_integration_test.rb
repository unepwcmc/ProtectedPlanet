require 'test_helper'

class Wdpa::Portal::ReleaseOrchestrationIntegrationTest < ActionDispatch::IntegrationTest
  LABEL = 'Jan2026'.freeze

  def setup
    # Guard: only run when Portal FDW is available (matches runbook prerequisites)
    fdw_check = ActiveRecord::Base.connection.execute(
      "SELECT to_regclass('portal_fdw.wdpa_iso3') AS exists"
    ).first

    skip 'Portal FDW schema/tables not available in test DB; full release orchestration cannot be exercised here' if fdw_check['exists'].nil?

    # Ensure no in-flight release and a clean staging state
    PortalRelease::Service.abort_current!
  end

  def teardown
    # Best-effort abort/cleanup to leave DB clean for other tests
    PortalRelease::Service.abort_current!
  end

  test 'dry run then resume from finalise_swap mimics portal_release_runbook' do
    # --- Phase 1: Dry run (stops after validate_and_manifest, no swap) ---
    ENV['PP_RELEASE_DRY_RUN'] = 'true'
    ENV['PP_RELEASE_START_AT'] = nil
    ENV['PP_RELEASE_STOP_AFTER'] = nil
    ENV['PP_RELEASE_ONLY_PHASES'] = nil

    assert_nothing_raised do
      Rake::Task['pp:portal:release'].reenable
      Rake::Task['pp:portal:release'].invoke(LABEL)
    end

    release = Release.order(created_at: :desc).first
    assert_not_nil release, 'Dry run should create a Release record'
    assert_equal LABEL, release.label
    assert_includes %w[importing succeeded swapped], release.state

    # --- Phase 2: Status check (pp:portal:status) ---
    Rake::Task['pp:portal:status'].reenable
    status_json = capture_io { Rake::Task['pp:portal:status'].invoke }.first
    parsed = JSON.parse(status_json)
    assert_equal release.id, parsed['id']
    assert_equal LABEL, parsed['label']

    # --- Phase 3: Resume from finalise_swap (actual swap and cleanup) ---
    ENV['PP_RELEASE_DRY_RUN'] = nil
    ENV['PP_RELEASE_START_AT'] = 'finalise_swap'
    ENV['PP_RELEASE_STOP_AFTER'] = nil

    assert_nothing_raised do
      Rake::Task['pp:portal:release'].reenable
      Rake::Task['pp:portal:release'].invoke(LABEL)
    end

    release.reload
    assert_equal 'succeeded', release.state
    assert release.manifest_url.present?, 'Finalised release should have a manifest URL set'

    # --- Phase 4: Backups exist after swap ---
    backups = Wdpa::Portal::Services::Core::TableRollbackService.list_available_backups
    assert backups.is_a?(Array)
    assert backups.any?, 'Expected at least one backup timestamp after a successful release'

    # --- Phase 5: Live tables and views look populated (high-level smoke checks) ---

    connection = ActiveRecord::Base.connection

    # All configured live tables should exist
    live_tables = Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash.keys
    live_tables.each do |table_name|
      assert connection.table_exists?(table_name), "Expected live table #{table_name} to exist after release"
    end

    # Core domain tables should have some data in a real release environment
    %w[protected_areas sources countries].each do |table_name|
      next unless connection.table_exists?(table_name)
      row_count = connection.select_value("SELECT COUNT(*) FROM #{table_name}").to_i
      assert_operator row_count, :>, 0, "Expected #{table_name} to contain data after release"
    end

    # Required portal materialized views (used for downloads) should exist
    required_view_keys = Wdpa::Portal::Config::PortalImportConfig.required_views_for_downloads
    views_config = Wdpa::Portal::Config::PortalImportConfig.portal_materialised_views_hash

    required_view_keys.each do |key|
      live_view = views_config.fetch(key)[:live]
      assert Wdpa::Portal::Managers::ViewManager.materialized_view_exists?(live_view),
             "Expected live materialized view #{live_view} to exist after release"
    end
  end
end

