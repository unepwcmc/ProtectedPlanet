require 'test_helper'

class Wdpa::Portal::ImportIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    # Create staging tables
    Wdpa::Portal::Managers::StagingTableManager.create_staging_tables

    # Create test portal views with sample data
    create_test_portal_views
  end

  def teardown
    # Clean up
    begin
      Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
    rescue => e
      Rails.logger.warn "Failed to drop staging tables: #{e.message}"
    end
    
    begin
      drop_test_portal_views
    rescue => e
      Rails.logger.warn "Failed to drop test portal views: #{e.message}"
    end
  end

  test 'complete portal import workflow' do
    # Test attribute import
    attribute_result = Wdpa::Portal::Importers::ProtectedArea::Attribute.import_to_staging
    assert attribute_result[:success], "Attribute import failed: #{attribute_result[:hard_errors]}"
    assert_equal 3, attribute_result[:imported_count]

    # Test geometry import
    geometry_result = Wdpa::Portal::Importers::ProtectedArea::Geometry.import_to_staging
    assert geometry_result[:protected_areas][:success],
      "Geometry import failed: #{geometry_result[:protected_areas][:hard_errors]}"

    # Test source import
    source_result = Wdpa::Portal::Importers::Source.import_to_staging
    assert source_result[:success], "Source import failed: #{source_result[:hard_errors]}"

    # Verify staging tables have data
    assert_equal 3, Staging::ProtectedArea.count
    assert_equal 1, Staging::Source.count

    # Verify data integrity
    staging_pa = Staging::ProtectedArea.first
    assert staging_pa.the_geom.present?, 'Geometry should be imported'
    assert staging_pa.wdpa_id.present?, 'WDPA ID should be present'
  end

  private

  def create_test_portal_views
    # Create test portal views with sample data
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW #{Wdpa::Portal::Config::PortalImportConfig.portal_view_for('polygons')} AS
      SELECT#{' '}
        1 as site_id,
        '1' as site_pid,
        'Test Polygon PA' as name_eng,
        'Test Polygon PA Original' as name,
        'Designated' as status,
        'Ia' as iucn_cat,
        'Terrestrial' as realm,
        'Test Designation' as desig_eng,
        'Test Governance' as gov_type,
        'Test Authority' as mang_auth,
        'Test Legal Status' as legal_status,
        'USA' as iso3,
        ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
      UNION ALL
      SELECT#{' '}
        2 as site_id,
        '2' as site_pid,
        'Test Polygon PA 2' as name_eng,
        'Test Polygon PA 2 Original' as name,
        'Designated' as status,
        'II' as iucn_cat,
        'Marine' as realm,
        'Test Designation' as desig_eng,
        'Test Governance' as gov_type,
        'Test Authority' as mang_auth,
        'Test Legal Status' as legal_status,
        'USA' as iso3,
        ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))') as wkb_geometry;

      CREATE MATERIALIZED VIEW #{Wdpa::Portal::Config::PortalImportConfig.portal_view_for('points')} AS
      SELECT#{' '}
        3 as site_id,
        '3' as site_pid,
        'Test Point PA' as name_eng,
        'Test Point PA Original' as name,
        'Designated' as status,
        'III' as iucn_cat,
        'Coastal' as realm,
        'Test Designation' as desig_eng,
        'Test Governance' as gov_type,
        'Test Authority' as mang_auth,
        'Test Legal Status' as legal_status,
        'USA' as iso3,
        ST_GeomFromText('POINT(0.5 0.5)') as wkb_geometry;

      CREATE MATERIALIZED VIEW #{Wdpa::Portal::Config::PortalImportConfig.portal_view_for('sources')} AS
      SELECT#{' '}
        1 as id,
        'Test Source' as data_title,
        'Test Description' as resp_party,
        '2024-01-01' as year,
        'en' as language;
    SQL
  end

  def drop_test_portal_views
    Wdpa::Portal::Config::PortalImportConfig.portal_views.each do |view|
      begin
        ActiveRecord::Base.connection.execute("DROP MATERIALIZED VIEW IF EXISTS #{view}")
      rescue => e
        Rails.logger.warn "Failed to drop materialized view #{view}: #{e.message}"
      end
    end
  end
end
