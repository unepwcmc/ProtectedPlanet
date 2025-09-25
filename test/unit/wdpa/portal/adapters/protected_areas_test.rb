require 'test_helper'

class Wdpa::Portal::Adapters::ProtectedAreasTest < ActiveSupport::TestCase
  def setup
    @adapter = Wdpa::Portal::Adapters::ProtectedAreas.new
    @connection = ActiveRecord::Base.connection

    # Mock the configuration
    @config = mock('PortalImportConfig')
    @config.stubs(:batch_import_protected_areas_from_view_size).returns(2)
    @config.stubs(:portal_protected_area_materialised_views).returns(%w[portal_standard_polygons
      portal_standard_points])

    Wdpa::Portal::Config::PortalImportConfig.stubs(:batch_import_protected_areas_from_view_size).returns(@config.batch_import_protected_areas_from_view_size)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_protected_area_materialised_views).returns(@config.portal_protected_area_materialised_views)
  end

  def teardown
    # Clean up any test views
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS portal_standard_polygons CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS portal_standard_points CASCADE')
  end

  test 'find_in_batches processes all views in batches' do
    # Create test materialized views
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_polygons AS
      SELECT 1 as wdpaid, 'Polygon 1' as name, ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
      UNION ALL
      SELECT 2 as wdpaid, 'Polygon 2' as name, ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))') as wkb_geometry
      UNION ALL
      SELECT 3 as wdpaid, 'Polygon 3' as name, ST_GeomFromText('POLYGON((2 2, 3 2, 3 3, 2 3, 2 2))') as wkb_geometry
    SQL

    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_points AS
      SELECT 4 as wdpaid, 'Point 1' as name, ST_GeomFromText('POINT(0.5 0.5)') as wkb_geometry
      UNION ALL
      SELECT 5 as wdpaid, 'Point 2' as name, ST_GeomFromText('POINT(1.5 1.5)') as wkb_geometry
    SQL

    batches = []
    @adapter.find_in_batches do |batch|
      batches << batch
    end

    # Should have 3 batches: 2 polygons + 1 polygon, then 2 points
    assert_equal 3, batches.length

    # First batch should have 2 polygons
    assert_equal 2, batches[0].length
    assert_equal 'Polygon 1', batches[0][0]['name']
    assert_equal 'Polygon 2', batches[0][1]['name']

    # Second batch should have 1 polygon
    assert_equal 1, batches[1].length
    assert_equal 'Polygon 3', batches[1][0]['name']

    # Third batch should have 2 points
    assert_equal 2, batches[2].length
    assert_equal 'Point 1', batches[2][0]['name']
    assert_equal 'Point 2', batches[2][1]['name']
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

  test 'find_in_batches handles single view' do
    # Mock single view
    @config.stubs(:portal_protected_area_materialised_views).returns(['portal_standard_polygons'])

    # Create test materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_polygons AS
      SELECT 1 as wdpaid, 'Polygon 1' as name, ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
    SQL

    batches = []
    @adapter.find_in_batches do |batch|
      batches << batch
    end

    # Should have 1 batch
    assert_equal 1, batches.length
    assert_equal 1, batches[0].length
    assert_equal 'Polygon 1', batches[0][0]['name']
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

  test 'count handles single view' do
    # Mock single view
    @config.stubs(:portal_protected_area_materialised_views).returns(['portal_standard_polygons'])

    # Create test materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_polygons AS
      SELECT 1 as wdpaid, 'Polygon 1' as name, ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
      UNION ALL
      SELECT 2 as wdpaid, 'Polygon 2' as name, ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))') as wkb_geometry
    SQL

    result = @adapter.count

    assert_equal 2, result
  end

  test 'find_in_batches respects batch size configuration' do
    # Mock smaller batch size
    @config.stubs(:batch_import_protected_areas_from_view_size).returns(1)

    # Create test materialized view with 3 records
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_polygons AS
      SELECT 1 as wdpaid, 'Polygon 1' as name, ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
      UNION ALL
      SELECT 2 as wdpaid, 'Polygon 2' as name, ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))') as wkb_geometry
      UNION ALL
      SELECT 3 as wdpaid, 'Polygon 3' as name, ST_GeomFromText('POLYGON((2 2, 3 2, 3 3, 2 3, 2 2))') as wkb_geometry
    SQL

    batches = []
    @adapter.find_in_batches do |batch|
      batches << batch
    end

    # Should have 3 batches of 1 record each
    assert_equal 3, batches.length
    batches.each do |batch|
      assert_equal 1, batch.length
    end
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
