require 'test_helper'

class Wdpa::Portal::Adapters::ProtectedAreasTest < ActiveSupport::TestCase
  def setup
    @adapter = Wdpa::Portal::Adapters::ProtectedAreas.new
    @connection = ActiveRecord::Base.connection

    # Mock the configuration
    @config = mock('PortalImportConfig')
    @config.stubs(:batch_import_protected_areas_from_view_size).returns(2)
    @config.stubs(:portal_protected_area_staging_materialised_views).returns(%w[portal_standard_polygons
      portal_standard_points])

    Wdpa::Portal::Config::PortalImportConfig.stubs(:batch_import_protected_areas_from_view_size).returns(@config.batch_import_protected_areas_from_view_size)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_protected_area_staging_materialised_views).returns(@config.portal_protected_area_staging_materialised_views)
  end

  def teardown
    # Clean up any test views
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS portal_standard_polygons CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS portal_standard_points CASCADE')
  end

  test 'find_in_batches respects sample_limit for a single view' do
    # Configure a single staging view and a small batch size
    @config.stubs(:portal_protected_area_staging_materialised_views).returns(['portal_standard_polygons'])
    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_protected_area_staging_materialised_views).returns(@config.portal_protected_area_staging_materialised_views)

    @config.stubs(:batch_import_protected_areas_from_view_size).returns(2)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:batch_import_protected_areas_from_view_size).returns(@config.batch_import_protected_areas_from_view_size)

    # Limit sampling to 3 rows so we should see two batches: 2 + 1
    Wdpa::Portal::ImportRuntimeConfig.stubs(:sample_limit).returns(3)
    Wdpa::Portal::ImportRuntimeConfig.stubs(:checkpoints?).returns(false)

    # Total count reported by the database
    @connection.stubs(:select_value).with('SELECT COUNT(*) FROM portal_standard_polygons').returns(10)

    # Expect two batch queries matching the computed LIMIT/OFFSET pairs
    @connection.expects(:select_all).with('SELECT * FROM portal_standard_polygons LIMIT 2 OFFSET 0')
               .returns([{ 'wdpaid' => 1 }, { 'wdpaid' => 2 }])
    @connection.expects(:select_all).with('SELECT * FROM portal_standard_polygons LIMIT 1 OFFSET 2')
               .returns([{ 'wdpaid' => 3 }])

    batches = []
    @adapter.find_in_batches do |batch|
      batches << batch
    end

    assert_equal 2, batches.length
    assert_equal [1, 2], batches[0].map { |row| row['wdpaid'] }
    assert_equal [3], batches[1].map { |row| row['wdpaid'] }
  end


  test 'find_in_batches handles empty views' do
    # Create empty materialized views
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_polygons AS
      SELECT 1 as wdpaid, 'test' as name, ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
      WHERE 1 = 0
    SQL

    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_points AS
      SELECT 1 as wdpaid, 'test' as name, ST_GeomFromText('POINT(0 0)') as wkb_geometry
      WHERE 1 = 0
    SQL

    batches = []
    @adapter.find_in_batches do |batch|
      batches << batch
    end

    # Should have no batches
    assert_equal 0, batches.length
  end


  test 'count returns total count from all views' do
    # Create test materialized views
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_polygons AS
      SELECT 1 as wdpaid, 'Polygon 1' as name, ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
      UNION ALL
      SELECT 2 as wdpaid, 'Polygon 2' as name, ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))') as wkb_geometry
    SQL

    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_points AS
      SELECT 3 as wdpaid, 'Point 1' as name, ST_GeomFromText('POINT(0.5 0.5)') as wkb_geometry
      UNION ALL
      SELECT 4 as wdpaid, 'Point 2' as name, ST_GeomFromText('POINT(1.5 1.5)') as wkb_geometry
      UNION ALL
      SELECT 5 as wdpaid, 'Point 3' as name, ST_GeomFromText('POINT(2.5 2.5)') as wkb_geometry
    SQL

    result = @adapter.count

    # Should be 2 polygons + 3 points = 5 total
    assert_equal 5, result
  end

  test 'count returns zero for empty views' do
    # Create empty materialized views
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_polygons AS
      SELECT 1 as wdpaid, 'test' as name, ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
      WHERE 1 = 0
    SQL

    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_points AS
      SELECT 1 as wdpaid, 'test' as name, ST_GeomFromText('POINT(0 0)') as wkb_geometry
      WHERE 1 = 0
    SQL

    result = @adapter.count

    assert_equal 0, result
  end

  test 'find_in_batches handles database errors gracefully' do
    # Mock the connection to raise an error
    @connection.expects(:select_value).raises(StandardError, 'Database error')

    assert_raises(StandardError, 'Database error') do
      @adapter.find_in_batches { |_batch| _ = batch }
    end
  end

  test 'count handles database errors gracefully' do
    # Mock the connection to raise an error
    @connection.expects(:select_value).raises(StandardError, 'Database error')

    assert_raises(StandardError, 'Database error') do
      @adapter.count
    end
  end
end
