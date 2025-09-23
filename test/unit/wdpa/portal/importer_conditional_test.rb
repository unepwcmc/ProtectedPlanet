require 'test_helper'

class Wdpa::Portal::ImporterConditionalTest < ActiveSupport::TestCase
  def setup
    # Stop any existing DatabaseCleaner
    DatabaseCleaner.clean

    # Use truncation strategy for this test to avoid transaction conflicts
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start

    # Create staging tables for testing
    Wdpa::Portal::Managers::StagingTableManager.create_staging_tables
  end

  def teardown
    # Clean up staging tables
    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables

    # Clean up and reset strategy
    DatabaseCleaner.clean
    DatabaseCleaner.strategy = :transaction
  end

  test 'runs all importers when protected areas import succeeds' do
    # Mock successful protected areas import
    Wdpa::Portal::Importers::Source.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 5,
      soft_errors: [],
      hard_errors: []
    })

    Wdpa::Portal::Importers::ProtectedArea.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 10,
      soft_errors: [],
      hard_errors: []
    })

    # Mock subsequent importers to return success
    Wdpa::Shared::Importer::GlobalStats.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 1,
      soft_errors: [],
      hard_errors: []
    })

    Wdpa::Portal::Importers::GreenList.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 2,
      soft_errors: [],
      hard_errors: []
    })

    Wdpa::Portal::Importers::Pame.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 3,
      soft_errors: [],
      hard_errors: []
    })

    Wdpa::Shared::Importer::StoryMapLinkList.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 4,
      soft_errors: [],
      hard_errors: []
    })

    Wdpa::Portal::Importers::CountryStatistics.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 6,
      soft_errors: [],
      hard_errors: []
    })

    # Run import
    result = Wdpa::Portal::Importer.import_data_to_staging_tables

    # Verify all importers were called and succeeded
    assert result[:sources][:success]
    assert result[:protected_areas][:success]
    assert result[:global_stats][:success]
    assert result[:green_list][:success]
    assert result[:pame][:success]
    assert result[:story_map_links][:success]
    assert result[:country_statistics][:success]

    # Verify imported counts
    assert_equal 5, result[:sources][:imported_count]
    assert_equal 10, result[:protected_areas][:imported_count]
    assert_equal 1, result[:global_stats][:imported_count]
    assert_equal 2, result[:green_list][:imported_count]
    assert_equal 3, result[:pame][:imported_count]
    assert_equal 4, result[:story_map_links][:imported_count]
    assert_equal 6, result[:country_statistics][:imported_count]
  end

  test 'skips subsequent importers when protected areas import has hard errors' do
    # Mock successful sources import
    Wdpa::Portal::Importers::Source.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 5,
      soft_errors: [],
      hard_errors: []
    })

    # Mock protected areas import with hard errors
    Wdpa::Portal::Importers::ProtectedArea.stubs(:import_to_staging).returns({
      success: false,
      imported_count: 0,
      soft_errors: [],
      hard_errors: ['Invalid realm: "Freshwater". Accepted values are: "Terrestrial", "Coastal", "Marine"']
    })

    # Run import
    result = Wdpa::Portal::Importer.import_data_to_staging_tables

    # Verify sources and protected areas results
    assert result[:sources][:success]
    refute result[:protected_areas][:success]
    assert_equal 1, result[:protected_areas][:hard_errors].count

    # Verify subsequent importers were skipped
    refute result[:global_stats][:success]
    refute result[:green_list][:success]
    refute result[:pame][:success]
    refute result[:story_map_links][:success]
    refute result[:country_statistics][:country_pa_geometry][:success]
    refute result[:country_statistics][:country_general_stats][:success]
    refute result[:country_statistics][:country_pame_stats][:success]

    # Verify skip messages
    assert_not_nil result[:global_stats][:hard_errors]
    assert_includes result[:global_stats][:hard_errors].first, 'Skipped due to hard errors in protected areas importer'
    assert_not_nil result[:green_list][:hard_errors]
    assert_includes result[:green_list][:hard_errors].first, 'Skipped due to hard errors in protected areas importer'
    assert_not_nil result[:pame][:hard_errors]
    assert_includes result[:pame][:hard_errors].first, 'Skipped due to hard errors in protected areas importer'
    assert_not_nil result[:story_map_links][:hard_errors]
    assert_includes result[:story_map_links][:hard_errors].first,
      'Skipped due to hard errors in protected areas importer'

    # country_statistics is a nested hash with multiple keys
    assert_not_nil result[:country_statistics][:country_pa_geometry][:hard_errors]
    assert_includes result[:country_statistics][:country_pa_geometry][:hard_errors].first,
      'Skipped due to hard errors in protected areas importer'
    assert_not_nil result[:country_statistics][:country_general_stats][:hard_errors]
    assert_includes result[:country_statistics][:country_general_stats][:hard_errors].first,
      'Skipped due to hard errors in protected areas importer'
    assert_not_nil result[:country_statistics][:country_pame_stats][:hard_errors]
    assert_includes result[:country_statistics][:country_pame_stats][:hard_errors].first,
      'Skipped due to hard errors in protected areas importer'

    # Verify imported counts are 0 for skipped importers
    assert_equal 0, result[:global_stats][:imported_count]
    assert_equal 0, result[:green_list][:imported_count]
    assert_equal 0, result[:pame][:imported_count]
    assert_equal 0, result[:story_map_links][:imported_count]
    assert_equal 0, result[:country_statistics][:country_pa_geometry][:imported_count]
    assert_equal 0, result[:country_statistics][:country_general_stats][:imported_count]
    assert_equal 0, result[:country_statistics][:country_pame_stats][:imported_count]
  end

  test 'runs subsequent importers when protected areas has only soft errors' do
    # Mock successful sources import
    Wdpa::Portal::Importers::Source.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 5,
      soft_errors: [],
      hard_errors: []
    })

    # Mock protected areas import with only soft errors (no hard errors)
    Wdpa::Portal::Importers::ProtectedArea.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 8,
      soft_errors: ['Some warning message'],
      hard_errors: [] # No hard errors
    })

    # Mock subsequent importers to return success
    Wdpa::Shared::Importer::GlobalStats.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 1,
      soft_errors: [],
      hard_errors: []
    })

    Wdpa::Portal::Importers::GreenList.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 2,
      soft_errors: [],
      hard_errors: []
    })

    Wdpa::Portal::Importers::Pame.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 3,
      soft_errors: [],
      hard_errors: []
    })

    Wdpa::Shared::Importer::StoryMapLinkList.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 4,
      soft_errors: [],
      hard_errors: []
    })

    Wdpa::Portal::Importers::CountryStatistics.stubs(:import_to_staging).returns({
      success: true,
      imported_count: 6,
      soft_errors: [],
      hard_errors: []
    })

    # Run import
    result = Wdpa::Portal::Importer.import_data_to_staging_tables

    # Verify all importers were called and succeeded
    assert result[:sources][:success]
    assert result[:protected_areas][:success]
    assert result[:global_stats][:success]
    assert result[:green_list][:success]
    assert result[:pame][:success]
    assert result[:story_map_links][:success]
    assert result[:country_statistics][:success]

    # Verify soft errors are preserved
    assert_equal 1, result[:protected_areas][:soft_errors].count
    assert_includes result[:protected_areas][:soft_errors].first, 'Some warning message'
  end
end
