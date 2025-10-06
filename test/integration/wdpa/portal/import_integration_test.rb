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
    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
    drop_test_portal_views
  end

  test 'complete portal import workflow' do
    # Test attribute import
    attribute_result = Wdpa::Portal::Importers::ProtectedAreaAttribute.import('protected_areas_new')
    assert attribute_result[:success], "Attribute import failed: #{attribute_result[:errors]}"
    assert_equal 2, attribute_result[:imported_count]

    # Test geometry import
    geometry_result = Wdpa::Portal::Importers::ProtectedAreaGeometry.import('protected_areas_new')
    assert geometry_result[:success], "Geometry import failed: #{geometry_result[:errors]}"

    # Test source import
    source_result = Wdpa::Portal::Importers::Source.import('sources_staging')
    assert source_result[:success], "Source import failed: #{source_result[:errors]}"

    # Verify staging tables have data
    assert_equal 2, ProtectedAreaNew.count
    assert_equal 1, SourceNew.count

    # Verify data integrity
    staging_pa = ProtectedAreaNew.first
    assert staging_pa.the_geom.present?, 'Geometry should be imported'
    assert staging_pa.site_id.present?, 'SITE ID should be present'
  end

  private

  def create_test_portal_views
    # Create test portal views with sample data
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW #{Wdpa::Portal::Config::PortalImportConfig.portal_materialised_view_for('polygons')} AS
      SELECT#{' '}
        1 as site_id,
        '1' as site_pid,
        'Test Polygon PA' as name,
        'Designated' as status,
        'Ia' as iucn_cat,
        ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry;
      UNION ALL
      SELECT#{' '}
        2 as site_id,
        '2' as site_pid,
        'Test Polygon PA 2' as name,
        'Designated' as status,
        'II' as iucn_cat,
        ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))') as wkb_geometry;

      CREATE MATERIALIZED VIEW #{Wdpa::Portal::Config::PortalImportConfig.portal_materialised_view_for('points')} AS
      SELECT#{' '}
        3 as site_id,
        '3' as site_pid,
        'Test Point PA' as name,
        'Designated' as status,
        'III' as iucn_cat,
        ST_GeomFromText('POINT(0.5 0.5)') as wkb_geometry;

      CREATE MATERIALIZED VIEW #{Wdpa::Portal::Config::PortalImportConfig.portal_materialised_view_for('sources')} AS
      SELECT#{' '}
        1 as id,
        'Test Source' as title,
        'Test Description' as description,
        2024 as year,
        'en' as language;
    SQL
  end

  def drop_test_portal_views
    Wdpa::Portal::Config::PortalImportConfig.portal_materialised_view_values.each do |view|
      ActiveRecord::Base.connection.execute("DROP MATERIALIZED VIEW IF EXISTS #{view}")
    end
  end
end
