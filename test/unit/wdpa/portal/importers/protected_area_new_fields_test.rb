require 'test_helper'

class Wdpa::Portal::Importers::ProtectedAreaNewFieldsTest < ActiveSupport::TestCase
  def setup
    # Create staging tables for testing
    Wdpa::Portal::Managers::StagingTableManager.create_staging_tables
  end

  def teardown
    # Clean up staging tables
    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
  end

  test 'imports new fields to protected areas' do
    # Mock portal data with new fields
    mock_portal_data = [
      {
        'wdpaid' => 1,
        'site_pid' => '1',
        'name' => 'Test Protected Area',
        'status' => 'Designated',
        'iucn_cat' => 'Ia',
        'realm' => 'Terrestrial',
        'governance_subtype' => 'Community',
        'inland_waters' => 'Yes',
        'ownership_subtype' => 'Private',
        'oecm_assessment' => 'Completed'
      }
    ]

    # Mock the relation to return our test data
    relation = mock
    relation.stubs(:find_in_batches).yields(mock_portal_data)

    Wdpa::Portal::Utils::PortalProtectedAreasRelation.stubs(:new).returns(relation)

    # Run import
    result = Wdpa::Portal::Importers::ProtectedAreaAttribute.import('protected_areas_new')

    # Verify result
    assert result[:success]
    assert_equal 1, result[:imported_count]

    # Verify new fields were imported
    staging_pa = ProtectedAreaNew.first
    assert_equal 'Community', staging_pa.governance_subtype
    assert_equal 'Yes', staging_pa.inland_waters
    assert_equal 'Private', staging_pa.ownership_subtype
    assert_equal 'Completed', staging_pa.oecm_assessment
    assert_equal 'Terrestrial', staging_pa.realm
    assert_equal false, staging_pa.marine # Derived from realm
    assert_equal 0, staging_pa.marine_type # Derived from realm
  end

  test 'imports new fields to protected area parcels' do
    # Mock portal data with new fields for parcels
    mock_portal_data = [
      {
        'wdpaid' => 1,
        'site_pid' => '1',
        'name' => 'Test Parcel',
        'status' => 'Designated',
        'iucn_cat' => 'Ia',
        'realm' => 'Marine',
        'governance_subtype' => 'Government',
        'inland_waters' => 'No',
        'ownership_subtype' => 'Public',
        'oecm_assessment' => 'Pending'
      }
    ]

    # Mock the relation to return our test data
    relation = mock
    relation.stubs(:find_in_batches).yields(mock_portal_data)

    Wdpa::Portal::Utils::PortalProtectedAreaParcelsRelation.stubs(:new).returns(relation)

    # Run import
    result = Wdpa::Portal::Importers::ProtectedAreaAttribute.import('protected_area_parcels_new')

    # Verify result
    assert result[:success]
    assert_equal 1, result[:imported_count]

    # Verify new fields were imported
    staging_parcel = ProtectedAreaParcelNew.first
    assert_equal 'Government', staging_parcel.governance_subtype
    assert_equal 'No', staging_parcel.inland_waters
    assert_equal 'Public', staging_parcel.ownership_subtype
    assert_equal 'Pending', staging_parcel.oecm_assessment
    assert_equal 'Marine', staging_parcel.realm
    assert_equal true, staging_parcel.marine # Derived from realm
    assert_equal 2, staging_parcel.marine_type # Derived from realm
  end

  test 'handles missing new fields gracefully' do
    # Mock portal data without new fields
    mock_portal_data = [
      {
        'wdpaid' => 1,
        'site_pid' => '1',
        'name' => 'Test Protected Area',
        'status' => 'Designated',
        'iucn_cat' => 'Ia',
        'realm' => 'Terrestrial'
      }
    ]

    relation = mock
    relation.stubs(:find_in_batches).yields(mock_portal_data)

    Wdpa::Portal::Utils::PortalProtectedAreasRelation.stubs(:new).returns(relation)

    # Run import
    result = Wdpa::Portal::Importers::ProtectedAreaAttribute.import('protected_areas_new')

    # Verify result
    assert result[:success]
    assert_equal 1, result[:imported_count]

    # Verify new fields are nil when not provided
    staging_pa = ProtectedAreaNew.first
    assert_nil staging_pa.governance_subtype
    assert_nil staging_pa.inland_waters
    assert_nil staging_pa.ownership_subtype
    assert_nil staging_pa.oecm_assessment
    assert_equal 'Terrestrial', staging_pa.realm
  end

  test 'validates realm field is required' do
    # Mock portal data without realm field
    mock_portal_data = [
      {
        'wdpaid' => 1,
        'site_pid' => '1',
        'name' => 'Test Protected Area',
        'status' => 'Designated',
        'iucn_cat' => 'Ia'
      }
    ]

    relation = mock
    relation.stubs(:find_in_batches).yields(mock_portal_data)

    Wdpa::Portal::Utils::PortalProtectedAreasRelation.stubs(:new).returns(relation)

    # Run import
    result = Wdpa::Portal::Importers::ProtectedAreaAttribute.import('protected_areas_new')

    # Verify result shows error for missing realm
    refute result[:success]
    assert_equal 0, result[:imported_count]
    assert result[:errors].any? { |error| error.include?('Invalid realm') }
  end
end
