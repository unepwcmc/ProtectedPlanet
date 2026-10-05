require 'test_helper'

# End-to-end check that a release which fails on every row reports WHY.
#
# Uses the real FDW fixture and the real import pipeline, then breaks the data
# the way it was first hit in practice: a site with no site_type. The column
# mapper passes site_type to TypeConverter, which calls .match on it and raises
# on nil, so every row fails.
#
# Before the fix this reported success for the attribute step and failed one step
# later with only "Target staging table staging_protected_areas does not exist or
# has no records" — the cause was visible nowhere a release operator would look.
class Wdpa::Portal::ReleaseErrorReportingIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    Wdpa::Portal::Services::Core::TableCleanupService.any_instance.stubs(:perform_vacuum_operations)
    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
    Wdpa::Portal::Managers::StagingTableManager.create_staging_tables
  end

  teardown do
    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
  end

  test 'a release that fails every row names the real cause in its hard errors' do
    load_portal_fdw_fixture
    seed_reference_data
    ActiveRecord::Base.lease_connection.execute('UPDATE portal_fdw.wdpas SET site_type_id = NULL')

    release = Release.create!(label: 'Jan2026')
    result = Wdpa::Portal::Importer.import(create_staging_materialized_views: true, release_id: release.id)

    refute result[:success], 'a release that imports no protected areas must not succeed'

    attribute_error = result[:hard_errors].find { |e| e.include?('failed to import') }
    assert attribute_error, "expected an attribute hard error; got: #{result[:hard_errors].inspect}"
    assert_match(/undefined method 'match' for nil/, attribute_error,
                 'the underlying row error must reach the release hard errors')

    # The real cause must come BEFORE the downstream geometry symptom, so whoever
    # reads the release notification sees it first.
    geometry_index = result[:hard_errors].index { |e| e.include?('does not exist or has no records') }
    assert geometry_index, 'the downstream geometry symptom is still reported'
    assert_operator result[:hard_errors].index(attribute_error), :<, geometry_index
  end

  # The happy path must be untouched: the same fixture with valid data still
  # imports cleanly and raises no new hard error.
  test 'a valid release raises no new hard error' do
    load_portal_fdw_fixture
    seed_reference_data

    release = Release.create!(label: 'Jan2026')
    result = Wdpa::Portal::Importer.import(create_staging_materialized_views: true, release_id: release.id)

    assert result[:success], "valid data must still import cleanly: #{Array(result[:hard_errors]).inspect}"
    assert_empty result[:hard_errors]
  end
end
