require 'test_helper'

class RealmTest < ActiveSupport::TestCase
  def setup
    @realm = Realm.create!(name: 'Terrestrial')
  end

  test 'realm has many protected areas' do
    pa1 = ProtectedArea.create!(
      site_id: 1,
      name: 'Test PA 1',
      designation: Designation.first || Designation.create!(name: 'Test Designation'),
      realm: @realm
    )
    pa2 = ProtectedArea.create!(
      site_id: 2,
      name: 'Test PA 2',
      designation: Designation.first || Designation.create!(name: 'Test Designation'),
      realm: @realm
    )

    assert_includes @realm.protected_areas, pa1
    assert_includes @realm.protected_areas, pa2
    assert_equal 2, @realm.protected_areas.count
  end

  test 'realm has many protected area parcels' do
    pa = ProtectedArea.create!(
      site_id: 1,
      name: 'Test PA',
      designation: Designation.first || Designation.create!(name: 'Test Designation'),
      realm: @realm
    )

    parcel1 = ProtectedAreaParcel.create!(
      site_id: 1,
      name: 'Test Parcel 1',
      realm: @realm
    )
    parcel2 = ProtectedAreaParcel.create!(
      site_id: 2,
      name: 'Test Parcel 2',
      realm: @realm
    )

    assert_includes @realm.protected_area_parcels, parcel1
    assert_includes @realm.protected_area_parcels, parcel2
    assert_equal 2, @realm.protected_area_parcels.count
  end

  test 'realm has many staging protected areas' do
    # Create staging table for testing
    Wdpa::Portal::Managers::StagingTableManager.create_staging_tables

    staging_pa1 = Staging::ProtectedArea.create!(
      site_id: 1,
      name: 'Test Staging PA 1',
      realm: @realm
    )
    staging_pa2 = Staging::ProtectedArea.create!(
      site_id: 2,
      name: 'Test Staging PA 2',
      realm: @realm
    )

    assert_includes @realm.staging_protected_areas, staging_pa1
    assert_includes @realm.staging_protected_areas, staging_pa2
    assert_equal 2, @realm.staging_protected_areas.count

    # Clean up
    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
  end

  test 'realm has many staging protected area parcels' do
    # Create staging table for testing
    Wdpa::Portal::Managers::StagingTableManager.create_staging_tables

    staging_parcel1 = Staging::ProtectedAreaParcel.create!(
      site_id: 1,
      name: 'Test Staging Parcel 1',
      realm: @realm
    )
    staging_parcel2 = Staging::ProtectedAreaParcel.create!(
      site_id: 2,
      name: 'Test Staging Parcel 2',
      realm: @realm
    )

    assert_includes @realm.staging_protected_area_parcels, staging_parcel1
    assert_includes @realm.staging_protected_area_parcels, staging_parcel2
    assert_equal 2, @realm.staging_protected_area_parcels.count

    # Clean up
    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
  end

  test 'realm name is required' do
    realm = Realm.new
    refute realm.valid?
    assert_includes realm.errors[:name], "can't be blank"
  end

  test 'realm name is unique' do
    Realm.create!(name: 'Terrestrial')
    duplicate_realm = Realm.new(name: 'Terrestrial')
    refute duplicate_realm.valid?
    assert_includes duplicate_realm.errors[:name], 'has already been taken'
  end

  test 'realm can be created with valid attributes' do
    realm = Realm.new(name: 'Marine')
    assert realm.valid?
    assert realm.save
  end
end
