require 'test_helper'

class Wdpa::Portal::ImporterTest < ActiveSupport::TestCase
  def setup
    # Mock the configuration
    @config = mock('PortalImportConfig')
    @config.stubs(:portal_views).returns(%w[portal_standard_polygons portal_standard_points
      portal_standard_sources])

    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_views).returns(@config.portal_views)
  end

  test '.import validates views and imports data to staging tables' do
    # Mock view validation
    Wdpa::Portal::Managers::ViewManager.expects(:validate_required_views_exist).returns(true)
    Wdpa::Portal::Managers::ViewManager.expects(:refresh_materialized_views)

    # Mock staging table management
    Wdpa::Portal::Managers::StagingTableManager.expects(:ensure_staging_tables_exist!).with(create_if_missing: true)
    Wdpa::Portal::Managers::StagingTableManager.expects(:ensure_staging_tables_exist!).with(create_if_missing: false)

    # Mock import results
    staging_results = {
      sources: { success: true, hard_errors: [] },
      protected_areas: { success: true, hard_errors: [] },
      global_stats: { success: true, hard_errors: [] },
      green_list: { success: true, hard_errors: [] },
      pame: { success: true, hard_errors: [] },
      story_map_links: { success: true, hard_errors: [] },
      country_statistics: { success: true, hard_errors: [] }
    }

    live_results = {
      country_overseas_territories: { success: true, hard_errors: [] },
      biopama_countries: { success: true, hard_errors: [] },
      aichi11_target: { success: true, hard_errors: [] }
    }

    Wdpa::Portal::Importer.expects(:import_data_to_staging_tables).returns(staging_results)
    Wdpa::Portal::Importer.expects(:update_data_in_live_tables).returns(live_results)

    result = Wdpa::Portal::Importer.import

    assert result[:success]
    assert_empty result[:hard_errors]
  end

  test '.import raises error when views do not exist' do
    Wdpa::Portal::Managers::ViewManager.expects(:validate_required_views_exist).returns(false)

    assert_raises(StandardError, /Required materialized views do not exist/) do
      Wdpa::Portal::Importer.import
    end
  end

  test '.import skips refresh when refresh_materialized_views is false' do
    Wdpa::Portal::Managers::ViewManager.expects(:validate_required_views_exist).returns(true)
    Wdpa::Portal::Managers::ViewManager.expects(:refresh_materialized_views).never

    Wdpa::Portal::Managers::StagingTableManager.expects(:ensure_staging_tables_exist!).twice

    staging_results = { sources: { success: true, hard_errors: [] } }
    live_results = {}

    Wdpa::Portal::Importer.expects(:import_data_to_staging_tables).returns(staging_results)
    Wdpa::Portal::Importer.expects(:update_data_in_live_tables).returns(live_results)

    Wdpa::Portal::Importer.import(refresh_materialized_views: false)
  end

  test '.import_data_to_staging_tables runs all importers when protected areas succeed' do
    # Mock successful protected areas import
    protected_areas_result = { success: true, hard_errors: [] }
    Wdpa::Portal::Importers::ProtectedArea.expects(:import_to_staging).returns(protected_areas_result)

    # Mock other importers
    Wdpa::Portal::Importers::Source.expects(:import_to_staging).returns({ success: true, hard_errors: [] })
    Wdpa::Shared::Importer::GlobalStats.expects(:import_to_staging).returns({ success: true, hard_errors: [] })
    Wdpa::Portal::Importers::GreenList.expects(:import_to_staging).returns({ success: true, hard_errors: [] })
    Wdpa::Portal::Importers::Pame.expects(:import_to_staging).returns({ success: true, hard_errors: [] })
    Wdpa::Shared::Importer::StoryMapLinkList.expects(:import_to_staging).returns({ success: true, hard_errors: [] })
    Wdpa::Portal::Importers::CountryStatistics.expects(:import_to_staging).returns({ success: true, hard_errors: [] })

    result = Wdpa::Portal::Importer.import_data_to_staging_tables

    assert_includes result.keys, :sources
    assert_includes result.keys, :protected_areas
    assert_includes result.keys, :global_stats
    assert_includes result.keys, :green_list
    assert_includes result.keys, :pame
    assert_includes result.keys, :story_map_links
    assert_includes result.keys, :country_statistics
  end

  test '.import_data_to_staging_tables skips subsequent importers when protected areas fail' do
    # Mock failed protected areas import
    protected_areas_result = { success: false, hard_errors: ['Hard error'] }
    Wdpa::Portal::Importers::ProtectedArea.expects(:import_to_staging).returns(protected_areas_result)

    # Mock source importer (runs before protected areas)
    Wdpa::Portal::Importers::Source.expects(:import_to_staging).returns({ success: true, hard_errors: [] })

    # Mock that subsequent importers are not called
    Wdpa::Shared::Importer::GlobalStats.expects(:import_to_staging).never
    Wdpa::Portal::Importers::GreenList.expects(:import_to_staging).never
    Wdpa::Portal::Importers::Pame.expects(:import_to_staging).never
    Wdpa::Shared::Importer::StoryMapLinkList.expects(:import_to_staging).never
    Wdpa::Portal::Importers::CountryStatistics.expects(:import_to_staging).never

    result = Wdpa::Portal::Importer.import_data_to_staging_tables

    # Should have skip messages for subsequent importers
    assert_includes result[:global_stats][:hard_errors].first, 'Skipped due to hard errors in protected areas importer'
    assert_includes result[:green_list][:hard_errors].first, 'Skipped due to hard errors in protected areas importer'
    assert_includes result[:pame][:hard_errors].first, 'Skipped due to hard errors in protected areas importer'
    assert_includes result[:story_map_links][:hard_errors].first,
      'Skipped due to hard errors in protected areas importer'
  end

  test '.update_data_in_live_tables runs live table updaters' do
    Wdpa::Shared::Importer::CountryOverseasTerritories.expects(:update_live_table).returns({ success: true })
    Wdpa::Shared::Importer::BiopamaCountries.expects(:update_live_table).returns({ success: true })
    Aichi11Target.expects(:update_live_table).returns({ success: true })

    result = Wdpa::Portal::Importer.update_data_in_live_tables

    assert_includes result.keys, :country_overseas_territories
    assert_includes result.keys, :biopama_countries
    assert_includes result.keys, :aichi11_target
  end

  test '.check_for_hard_errors returns true when hard errors exist' do
    staging_results = {
      sources: { success: true, hard_errors: [] },
      protected_areas: { success: false, hard_errors: ['Hard error'] }
    }
    live_results = {}

    result = Wdpa::Portal::Importer.check_for_hard_errors(staging_results, live_results)
    assert result
  end

  test '.check_for_hard_errors returns false when no hard errors' do
    staging_results = {
      sources: { success: true, hard_errors: [] },
      protected_areas: { success: true, hard_errors: [] }
    }
    live_results = {}

    result = Wdpa::Portal::Importer.check_for_hard_errors(staging_results, live_results)
    refute result
  end

  test '.check_for_hard_errors_recursive finds nested hard errors' do
    hash = {
      level1: {
        level2: {
          hard_errors: ['Nested error']
        }
      }
    }

    result = Wdpa::Portal::Importer.check_for_hard_errors_recursive(hash, 'test')
    assert result
  end

  test '.check_for_hard_errors_recursive returns false for non-hash input' do
    result = Wdpa::Portal::Importer.check_for_hard_errors_recursive('not a hash', 'test')
    refute result
  end

  test '.import handles exceptions gracefully' do
    Wdpa::Portal::Managers::ViewManager.expects(:validate_required_views_exist).raises(StandardError, 'Test error')

    result = Wdpa::Portal::Importer.import

    refute result[:success]
    assert_includes result[:hard_errors].first, 'Portal import failed: Test error'
  end
end
