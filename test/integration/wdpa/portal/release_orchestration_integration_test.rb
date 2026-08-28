require 'test_helper'

class Wdpa::Portal::ReleaseOrchestrationIntegrationTest < ActionDispatch::IntegrationTest
  LABEL = 'Jan2026'.freeze

  def setup
    # Guard: only run when Portal FDW is available (matches runbook prerequisites)
    fdw_check = ActiveRecord::Base.connection.execute(
      "SELECT to_regclass('portal_fdw.wdpa_iso3') AS exists"
    ).first

    skip 'Portal FDW schema/tables not available in test DB; full release orchestration cannot be exercised here' if fdw_check['exists'].nil?

    # The importer matches portal rows to countries by ISO3; with none loaded every
    # row is dropped and the release has nothing to promote.
    seed_reference_data

    # post_swap re-indexes through Elasticsearch, which WebMock would block; the ES
    # container is on the compose network, not localhost, so the allowance misses it.
    WebMock.disable!

    # VACUUM cannot run inside a transaction, and this test runs in one. The release
    # itself never does -- it is a rake task -- so the vacuum is the one step of
    # cleanup that can only be exercised outside the suite.
    Wdpa::Portal::Services::Core::TableCleanupService.any_instance.stubs(:perform_vacuum_operations)

    # The suite does not load rake tasks, and this test drives the release through them.
    require 'rake'
    Rails.application.load_tasks if Rake::Task.tasks.empty?

    # Ensure no in-flight release and a clean staging state
    PortalRelease::Service.abort_current!
  end

  def teardown
    WebMock.enable!

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
    # A dry run stops after validate_and_manifest, which is what leaves 'validating'.
    assert_equal 'validating', release.state

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

    # Every run creates its own Release row, so the resume is a new record rather
    # than an update of the dry run's.
    resumed = Release.order(created_at: :desc).first
    assert_not_equal release.id, resumed.id
    assert_equal 'succeeded', resumed.state
    # The manifest is written by validate_and_manifest, which the resume starts after,
    # so it belongs to the dry run's release.
    assert release.reload.manifest_url.present?, 'The dry run should have written a manifest URL'

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

