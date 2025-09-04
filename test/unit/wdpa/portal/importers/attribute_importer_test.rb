require 'test_helper'

class Wdpa::Portal::Importers::AttributeImporterTest < ActiveSupport::TestCase
  def setup
    # Create staging table for testing
    Wdpa::Portal::Utils::StagingTableManager.create_staging_tables
  end

  def teardown
    # Clean up staging tables
    Wdpa::Portal::Utils::StagingTableManager.drop_staging_tables
  end

  test 'imports protected areas to staging table' do
    # Mock portal data
    mock_portal_data = [
      {
        'wdpaid' => 1,
        'wdpa_pid' => '1',
        'name' => 'Test Protected Area',
        'status' => 'Designated',
        'iucn_cat' => 'Ia',
        'wkb_geometry' => 'POINT(0 0)'
      }
    ]

    # Mock the relation to return our test data
    relation = mock
    relation.stubs(:find_in_batches).yields(mock_portal_data)

    Wdpa::Portal::Utils::PortalProtectedAreasRelation.stubs(:new).returns(relation)

    # Run import
    result = Wdpa::Portal::Importers::AttributeImporter.import('protected_areas_new')

    # Verify result
    assert result[:success]
    assert_equal 1, result[:imported_count]
    assert_empty result[:errors]

    # Verify data was imported
    staging_pa = ProtectedAreaNew.first
    assert_equal 1, staging_pa.wdpa_id
    assert_equal 'Test Protected Area', staging_pa.name
  end

  test 'handles errors gracefully' do
    # Mock portal data with invalid record
    mock_portal_data = [
      {
        'wdpaid' => 1,
        'wdpa_pid' => '1',
        'name' => nil, # Invalid: name is required
        'status' => 'Designated',
        'iucn_cat' => 'Ia'
      }
    ]

    relation = mock
    relation.stubs(:find_in_batches).yields(mock_portal_data)

    Wdpa::Portal::Utils::PortalProtectedAreasRelation.stubs(:new).returns(relation)

    # Run import
    result = Wdpa::Portal::Importers::AttributeImporter.import('protected_areas_new')

    # Verify result
    refute result[:success]
    assert_equal 0, result[:imported_count]
    assert_equal 1, result[:errors].count
    assert_includes result[:errors].first, 'Standardization error'
  end
end
