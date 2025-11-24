require 'test_helper'

class ModelStagingRelationshipsTest < ActiveSupport::TestCase
  def setup
    # Create staging tables for testing
    Wdpa::Portal::Managers::StagingTableManager.create_staging_tables

    # Create test models
    @designation = Designation.create!(name: 'Test Designation')
    @management_authority = ManagementAuthority.create!(name: 'Test Authority')
    @legal_status = LegalStatus.create!(name: 'Test Legal Status')
    @iucn_category = IucnCategory.create!(name: 'Ia')
    @governance = Governance.create!(name: 'Test Governance')
    @realm = Realm.create!(name: 'Terrestrial')
  end

  def teardown
    # Clean up staging tables
    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
  end

  test 'designation has staging relationships' do
    staging_pa = Staging::ProtectedArea.create!(
      site_id: 1,
      name: 'Test Staging PA',
      designation: @designation
    )
    staging_parcel = Staging::ProtectedAreaParcel.create!(
      site_id: 1,
      name: 'Test Staging Parcel',
      designation: @designation
    )

    assert_includes @designation.staging_protected_areas, staging_pa
    assert_includes @designation.staging_protected_area_parcels, staging_parcel
  end

  test 'management authority has staging relationships' do
    staging_pa = Staging::ProtectedArea.create!(
      site_id: 1,
      name: 'Test Staging PA',
      management_authority: @management_authority
    )
    staging_parcel = Staging::ProtectedAreaParcel.create!(
      site_id: 1,
      name: 'Test Staging Parcel',
      management_authority: @management_authority
    )

    assert_includes @management_authority.staging_protected_areas, staging_pa
    assert_includes @management_authority.staging_protected_area_parcels, staging_parcel
  end

  test 'legal status has staging relationships' do
    staging_pa = Staging::ProtectedArea.create!(
      site_id: 1,
      name: 'Test Staging PA',
      legal_status: @legal_status
    )
    staging_parcel = Staging::ProtectedAreaParcel.create!(
      site_id: 1,
      name: 'Test Staging Parcel',
      legal_status: @legal_status
    )

    assert_includes @legal_status.staging_protected_areas, staging_pa
    assert_includes @legal_status.staging_protected_area_parcels, staging_parcel
  end

  test 'iucn category has staging relationships' do
    staging_pa = Staging::ProtectedArea.create!(
      site_id: 1,
      name: 'Test Staging PA',
      iucn_category: @iucn_category
    )
    staging_parcel = Staging::ProtectedAreaParcel.create!(
      site_id: 1,
      name: 'Test Staging Parcel',
      iucn_category: @iucn_category
    )

    assert_includes @iucn_category.staging_protected_areas, staging_pa
    assert_includes @iucn_category.staging_protected_area_parcels, staging_parcel
  end

  test 'governance has staging relationships' do
    staging_pa = Staging::ProtectedArea.create!(
      site_id: 1,
      name: 'Test Staging PA',
      governance: @governance
    )
    staging_parcel = Staging::ProtectedAreaParcel.create!(
      site_id: 1,
      name: 'Test Staging Parcel',
      governance: @governance
    )

    assert_includes @governance.staging_protected_areas, staging_pa
    assert_includes @governance.staging_protected_area_parcels, staging_parcel
  end

  test 'realm has staging relationships' do
    staging_pa = Staging::ProtectedArea.create!(
      site_id: 1,
      name: 'Test Staging PA',
      realm: @realm
    )
    staging_parcel = Staging::ProtectedAreaParcel.create!(
      site_id: 1,
      name: 'Test Staging Parcel',
      realm: @realm
    )

    assert_includes @realm.staging_protected_areas, staging_pa
    assert_includes @realm.staging_protected_area_parcels, staging_parcel
  end

  test 'staging relationships return correct class names' do
    staging_pa = @designation.staging_protected_areas.build(site_id: 1, name: 'Test')
    staging_parcel = @designation.staging_protected_area_parcels.build(site_id: 1, name: 'Test')

    assert_instance_of Staging::ProtectedArea, staging_pa
    assert_instance_of Staging::ProtectedAreaParcel, staging_parcel
  end

  test 'staging relationships can be queried' do
    # Create multiple staging records
    Staging::ProtectedArea.create!(
      site_id: 1,
      name: 'Test Staging PA 1',
      designation: @designation
    )
    Staging::ProtectedArea.create!(
      site_id: 2,
      name: 'Test Staging PA 2',
      designation: @designation
    )

    # Test querying
    assert_equal 2, @designation.staging_protected_areas.count
    assert_equal 2, @designation.staging_protected_areas.pluck(:name).count
  end
end
