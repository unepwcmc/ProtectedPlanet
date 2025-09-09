require 'test_helper'

class AddNewFieldsMigrationTest < ActiveSupport::TestCase
  def setup
    # Run the migration
    ActiveRecord::Migration.run(:up, AddNewFieldsToProtectedAreasAndParcels)
  end

  def teardown
    # Rollback the migration
    ActiveRecord::Migration.run(:down, AddNewFieldsToProtectedAreasAndParcels)
  end

  test 'adds new fields to protected_areas table' do
    # Check that the new columns exist
    assert ProtectedArea.column_names.include?('governance_subtype')
    assert ProtectedArea.column_names.include?('inland_waters')
    assert ProtectedArea.column_names.include?('ownership_subtype')
    assert ProtectedArea.column_names.include?('oecm_assessment')

    # Check column types
    governance_subtype_column = ProtectedArea.columns.find { |c| c.name == 'governance_subtype' }
    inland_waters_column = ProtectedArea.columns.find { |c| c.name == 'inland_waters' }
    ownership_subtype_column = ProtectedArea.columns.find { |c| c.name == 'ownership_subtype' }
    oecm_assessment_column = ProtectedArea.columns.find { |c| c.name == 'oecm_assessment' }

    assert_equal :string, governance_subtype_column.type
    assert_equal :string, inland_waters_column.type
    assert_equal :string, ownership_subtype_column.type
    assert_equal :string, oecm_assessment_column.type
  end

  test 'adds new fields to protected_area_parcels table' do
    # Check that the new columns exist
    assert ProtectedAreaParcel.column_names.include?('governance_subtype')
    assert ProtectedAreaParcel.column_names.include?('inland_waters')
    assert ProtectedAreaParcel.column_names.include?('ownership_subtype')
    assert ProtectedAreaParcel.column_names.include?('oecm_assessment')

    # Check column types
    governance_subtype_column = ProtectedAreaParcel.columns.find { |c| c.name == 'governance_subtype' }
    inland_waters_column = ProtectedAreaParcel.columns.find { |c| c.name == 'inland_waters' }
    ownership_subtype_column = ProtectedAreaParcel.columns.find { |c| c.name == 'ownership_subtype' }
    oecm_assessment_column = ProtectedAreaParcel.columns.find { |c| c.name == 'oecm_assessment' }

    assert_equal :string, governance_subtype_column.type
    assert_equal :string, inland_waters_column.type
    assert_equal :string, ownership_subtype_column.type
    assert_equal :string, oecm_assessment_column.type
  end

  test 'can create protected area with new fields' do
    designation = Designation.create!(name: 'Test Designation')
    realm = Realm.create!(name: 'Terrestrial')

    protected_area = ProtectedArea.create!(
      wdpa_id: 1,
      name: 'Test PA',
      designation: designation,
      realm: realm,
      governance_subtype: 'Community',
      inland_waters: 'Yes',
      ownership_subtype: 'Private',
      oecm_assessment: 'Completed'
    )

    assert_equal 'Community', protected_area.governance_subtype
    assert_equal 'Yes', protected_area.inland_waters
    assert_equal 'Private', protected_area.ownership_subtype
    assert_equal 'Completed', protected_area.oecm_assessment
  end

  test 'can create protected area parcel with new fields' do
    realm = Realm.create!(name: 'Marine')

    parcel = ProtectedAreaParcel.create!(
      wdpa_id: 1,
      name: 'Test Parcel',
      realm: realm,
      governance_subtype: 'Government',
      inland_waters: 'No',
      ownership_subtype: 'Public',
      oecm_assessment: 'Pending'
    )

    assert_equal 'Government', parcel.governance_subtype
    assert_equal 'No', parcel.inland_waters
    assert_equal 'Public', parcel.ownership_subtype
    assert_equal 'Pending', parcel.oecm_assessment
  end

  test 'new fields can be nil' do
    designation = Designation.create!(name: 'Test Designation')
    realm = Realm.create!(name: 'Terrestrial')

    protected_area = ProtectedArea.create!(
      wdpa_id: 1,
      name: 'Test PA',
      designation: designation,
      realm: realm
    )

    assert_nil protected_area.governance_subtype
    assert_nil protected_area.inland_waters
    assert_nil protected_area.ownership_subtype
    assert_nil protected_area.oecm_assessment
  end

  test 'migration can be rolled back' do
    # This test ensures the migration can be rolled back without errors
    assert_nothing_raised do
      ActiveRecord::Migration.run(:down, AddNewFieldsToProtectedAreasAndParcels)
    end

    # Verify columns are removed
    refute ProtectedArea.column_names.include?('governance_subtype')
    refute ProtectedArea.column_names.include?('inland_waters')
    refute ProtectedArea.column_names.include?('ownership_subtype')
    refute ProtectedArea.column_names.include?('oecm_assessment')

    refute ProtectedAreaParcel.column_names.include?('governance_subtype')
    refute ProtectedAreaParcel.column_names.include?('inland_waters')
    refute ProtectedAreaParcel.column_names.include?('ownership_subtype')
    refute ProtectedAreaParcel.column_names.include?('oecm_assessment')
  end
end
