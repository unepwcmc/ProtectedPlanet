require 'test_helper'

class Wdpa::Portal::CompleteImportWorkflowTest < ActionDispatch::IntegrationTest
  def setup
    # Create staging tables
    Wdpa::Portal::Managers::StagingTableManager.create_staging_tables

    # Create test portal views with comprehensive sample data
    create_test_portal_views_with_new_fields

    # Create required lookup data
    create_lookup_data
  end

  def teardown
    # Clean up
    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
    drop_test_portal_views
  end

  test 'complete portal import workflow with new fields' do
    # Run the complete import process
    result = Wdpa::Portal::Importer.import_data_to_staging_tables

    # Verify overall success
    assert result[:sources][:success], "Sources import failed: #{result[:sources][:hard_errors]}"
    assert result[:protected_areas][:success],
      "Protected areas import failed: #{result[:protected_areas][:hard_errors]}"
    assert result[:global_stats][:success], "Global stats import failed: #{result[:global_stats][:hard_errors]}"
    assert result[:green_list][:success], "Green list import failed: #{result[:green_list][:hard_errors]}"
    assert result[:pame][:success], "PAME import failed: #{result[:pame][:hard_errors]}"
    assert result[:story_map_links][:success],
      "Story map links import failed: #{result[:story_map_links][:hard_errors]}"
    assert result[:country_statistics][:success],
      "Country statistics import failed: #{result[:country_statistics][:hard_errors]}"

    # Verify imported counts
    assert_equal 2, result[:sources][:imported_count]
    assert_equal 3, result[:protected_areas][:imported_count]

    # Verify staging tables have data
    assert_equal 2, Staging::Source.count
    assert_equal 3, Staging::ProtectedArea.count
    assert_equal 2, Staging::ProtectedAreaParcel.count

    # Verify new fields were imported correctly
    terrestrial_pa = Staging::ProtectedArea.find_by(realm: Realm.find_by(name: 'Terrestrial'))
    assert_equal 'Community', terrestrial_pa.governance_subtype
    assert_equal 'Yes', terrestrial_pa.inland_waters
    assert_equal 'Private', terrestrial_pa.ownership_subtype
    assert_equal 'Completed', terrestrial_pa.oecm_assessment
    assert_equal false, terrestrial_pa.marine
    assert_equal 0, terrestrial_pa.marine_type

    marine_pa = Staging::ProtectedArea.find_by(realm: Realm.find_by(name: 'Marine'))
    assert_equal 'Government', marine_pa.governance_subtype
    assert_equal 'No', marine_pa.inland_waters
    assert_equal 'Public', marine_pa.ownership_subtype
    assert_equal 'Pending', marine_pa.oecm_assessment
    assert_equal true, marine_pa.marine
    assert_equal 2, marine_pa.marine_type

    coastal_pa = Staging::ProtectedArea.find_by(realm: Realm.find_by(name: 'Coastal'))
    assert_equal 'Indigenous', coastal_pa.governance_subtype
    assert_equal 'Partial', coastal_pa.inland_waters
    assert_equal 'Mixed', coastal_pa.ownership_subtype
    assert_equal 'In Progress', coastal_pa.oecm_assessment
    assert_equal true, coastal_pa.marine
    assert_equal 1, coastal_pa.marine_type

    # Verify relationships are working
    assert_equal 3, Realm.find_by(name: 'Terrestrial').staging_protected_areas.count
    assert_equal 1, Realm.find_by(name: 'Marine').staging_protected_areas.count
    assert_equal 1, Realm.find_by(name: 'Coastal').staging_protected_areas.count

    # Verify data integrity
    staging_pa = Staging::ProtectedArea.first
    assert staging_pa.the_geom.present?, 'Geometry should be imported'
    assert staging_pa.wdpa_id.present?, 'WDPA ID should be present'
    assert staging_pa.realm.present?, 'Realm should be present'
    assert staging_pa.designation.present?, 'Designation should be present'
  end

  test 'import workflow handles realm validation errors' do
    # Create portal view with invalid realm data
    create_test_portal_views_with_invalid_realm

    # Run the complete import process
    result = Wdpa::Portal::Importer.import_data_to_staging_tables

    # Verify protected areas import fails due to invalid realm
    refute result[:protected_areas][:success]
    assert result[:protected_areas][:hard_errors].any? { |error| error.include?('Invalid realm') }

    # Verify subsequent importers are skipped
    refute result[:global_stats][:success]
    refute result[:green_list][:success]
    refute result[:pame][:success]
    refute result[:story_map_links][:success]
    refute result[:country_statistics][:success]

    # Verify skip messages
    assert_includes result[:global_stats][:hard_errors].first, 'Skipped due to hard errors in protected areas importer'
  end

  private

  def create_test_portal_views_with_new_fields
    # Create test portal views with comprehensive sample data including new fields
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW #{Wdpa::Portal::Config::PortalImportConfig.portal_materialised_view_for('polygons')} AS
      SELECT#{' '}
        1 as wdpaid,
        '1' as site_pid,
        'Test Terrestrial PA' as name,
        'Designated' as status,
        'Ia' as iucn_cat,
        'Terrestrial' as realm,
        'Community' as governance_subtype,
        'Yes' as inland_waters,
        'Private' as ownership_subtype,
        'Completed' as oecm_assessment,
        ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
      UNION ALL
      SELECT#{' '}
        2 as wdpaid,
        '2' as site_pid,
        'Test Marine PA' as name,
        'Designated' as status,
        'II' as iucn_cat,
        'Marine' as realm,
        'Government' as governance_subtype,
        'No' as inland_waters,
        'Public' as ownership_subtype,
        'Pending' as oecm_assessment,
        ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))') as wkb_geometry
      UNION ALL
      SELECT#{' '}
        3 as wdpaid,
        '3' as site_pid,
        'Test Coastal PA' as name,
        'Designated' as status,
        'III' as iucn_cat,
        'Coastal' as realm,
        'Indigenous' as governance_subtype,
        'Partial' as inland_waters,
        'Mixed' as ownership_subtype,
        'In Progress' as oecm_assessment,
        ST_GeomFromText('POLYGON((2 2, 3 2, 3 3, 2 3, 2 2))') as wkb_geometry;

      CREATE MATERIALIZED VIEW #{Wdpa::Portal::Config::PortalImportConfig.portal_materialised_view_for('points')} AS
      SELECT#{' '}
        4 as wdpaid,
        '4' as site_pid,
        'Test Point PA' as name,
        'Designated' as status,
        'IV' as iucn_cat,
        'Terrestrial' as realm,
        'Community' as governance_subtype,
        'Yes' as inland_waters,
        'Private' as ownership_subtype,
        'Completed' as oecm_assessment,
        ST_GeomFromText('POINT(0.5 0.5)') as wkb_geometry
      UNION ALL
      SELECT#{' '}
        5 as wdpaid,
        '5' as site_pid,
        'Test Marine Point PA' as name,
        'Designated' as status,
        'V' as iucn_cat,
        'Marine' as realm,
        'Government' as governance_subtype,
        'No' as inland_waters,
        'Public' as ownership_subtype,
        'Pending' as oecm_assessment,
        ST_GeomFromText('POINT(1.5 1.5)') as wkb_geometry;

      CREATE MATERIALIZED VIEW #{Wdpa::Portal::Config::PortalImportConfig.portal_materialised_view_for('sources')} AS
      SELECT#{' '}
        1 as id,
        'Test Source 1' as title,
        'Test Description 1' as description,
        2024 as year,
        'en' as language
      UNION ALL
      SELECT#{' '}
        2 as id,
        'Test Source 2' as title,
        'Test Description 2' as description,
        2023 as year,
        'en' as language;
    SQL
  end

  def create_test_portal_views_with_invalid_realm
    # Create test portal views with invalid realm data
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW #{Wdpa::Portal::Config::PortalImportConfig.portal_materialised_view_for('polygons')} AS
      SELECT#{' '}
        1 as wdpaid,
        '1' as site_pid,
        'Test PA with Invalid Realm' as name,
        'Designated' as status,
        'Ia' as iucn_cat,
        'Freshwater' as realm,
        'Community' as governance_subtype,
        'Yes' as inland_waters,
        'Private' as ownership_subtype,
        'Completed' as oecm_assessment,
        ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry;
    SQL
  end

  def create_lookup_data
    # Create required lookup data
    Realm.create!(name: 'Terrestrial')
    Realm.create!(name: 'Marine')
    Realm.create!(name: 'Coastal')

    Designation.create!(name: 'Test Designation')
    ManagementAuthority.create!(name: 'Test Authority')
    LegalStatus.create!(name: 'Test Legal Status')
    IucnCategory.create!(name: 'Ia')
    IucnCategory.create!(name: 'II')
    IucnCategory.create!(name: 'III')
    IucnCategory.create!(name: 'IV')
    IucnCategory.create!(name: 'V')
    Governance.create!(name: 'Test Governance')
  end

  def drop_test_portal_views
    Wdpa::Portal::Config::PortalImportConfig.portal_materialised_view_values.each do |view|
      ActiveRecord::Base.connection.execute("DROP MATERIALIZED VIEW IF EXISTS #{view}")
    end
  end
end
