require 'test_helper'

class Wdpa::Portal::Managers::ViewManagerTest < ActiveSupport::TestCase
  def setup
    @connection = ActiveRecord::Base.connection

    # Mock the configuration
    @config = mock('PortalImportConfig')
    @config.stubs(:portal_materialised_view_values).returns(%w[portal_standard_polygons portal_standard_points
      portal_standard_sources])

    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_materialised_view_values).returns(@config.portal_materialised_view_values)
  end

  def teardown
    # Clean up any test views
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS portal_standard_polygons CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS portal_standard_points CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS portal_standard_sources CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS test_view CASCADE')
  end

  test 'view_exists? returns true for existing view' do
    # Create a test materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW test_view AS
      SELECT 1 as id, 'test' as name
    SQL

    result = Wdpa::Portal::Managers::ViewManager.view_exists?('test_view')
    assert result
  end

  test 'view_exists? returns false for non-existent view' do
    result = Wdpa::Portal::Managers::ViewManager.view_exists?('non_existent_view')
    refute result
  end

  test 'view_exists? handles query errors gracefully' do
    # Mock the connection to raise an error
    @connection.expects(:execute).with('SELECT 1 FROM invalid_view LIMIT 1').raises(StandardError,
      'View does not exist')

    result = Wdpa::Portal::Managers::ViewManager.view_exists?('invalid_view')
    refute result
  end

  test 'validate_required_views_exist returns true when all views exist' do
    # Create all required views
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_polygons AS
      SELECT 1 as wdpaid, 'test' as name, ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
    SQL

    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_points AS
      SELECT 1 as wdpaid, 'test' as name, ST_GeomFromText('POINT(0 0)') as wkb_geometry
    SQL

    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_sources AS
      SELECT 1 as id, 'test' as title
    SQL

    result = Wdpa::Portal::Managers::ViewManager.validate_required_views_exist
    assert result
  end

  test 'validate_required_views_exist returns false when views are missing' do
    # Don't create any views
    result = Wdpa::Portal::Managers::ViewManager.validate_required_views_exist
    refute result
  end

  test 'validate_required_views_exist returns false when some views are missing' do
    # Create only one view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_polygons AS
      SELECT 1 as wdpaid, 'test' as name, ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
    SQL

    result = Wdpa::Portal::Managers::ViewManager.validate_required_views_exist
    refute result
  end

  test 'refresh_materialized_views refreshes all configured views' do
    # Create test views
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_polygons AS
      SELECT 1 as wdpaid, 'test' as name, ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
    SQL

    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_points AS
      SELECT 1 as wdpaid, 'test' as name, ST_GeomFromText('POINT(0 0)') as wkb_geometry
    SQL

    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_sources AS
      SELECT 1 as id, 'test' as title
    SQL

    # Mock the refresh_view_concurrently method to avoid actual refresh
    Wdpa::Portal::Managers::ViewManager.expects(:refresh_view_concurrently).with('portal_standard_polygons')
    Wdpa::Portal::Managers::ViewManager.expects(:refresh_view_concurrently).with('portal_standard_points')
    Wdpa::Portal::Managers::ViewManager.expects(:refresh_view_concurrently).with('portal_standard_sources')

    Wdpa::Portal::Managers::ViewManager.refresh_materialized_views
  end

  test 'refresh_view_concurrently executes REFRESH MATERIALIZED VIEW CONCURRENTLY' do
    # Create a test view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW test_view AS
      SELECT 1 as id, 'test' as name
    SQL

    # Mock the connection to expect the concurrent refresh
    @connection.expects(:execute).with('REFRESH MATERIALIZED VIEW CONCURRENTLY test_view')

    Wdpa::Portal::Managers::ViewManager.refresh_view_concurrently('test_view')
  end

  test 'refresh_view_concurrently handles PG::ObjectNotInPrerequisiteState error' do
    # Create a test view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW test_view AS
      SELECT 1 as id, 'test' as name
    SQL

    # Mock the connection to raise the specific error
    @connection.expects(:execute).with('REFRESH MATERIALIZED VIEW CONCURRENTLY test_view').raises(PG::ObjectNotInPrerequisiteState.new('Indexes may not have been created properly'))

    assert_raises(PG::ObjectNotInPrerequisiteState) do
      Wdpa::Portal::Managers::ViewManager.refresh_view_concurrently('test_view')
    end
  end

  test 'refresh_view_concurrently handles general errors' do
    # Create a test view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW test_view AS
      SELECT 1 as id, 'test' as name
    SQL

    # Mock the connection to raise a general error
    @connection.expects(:execute).with('REFRESH MATERIALIZED VIEW CONCURRENTLY test_view').raises(StandardError,
      'General error')

    assert_raises(StandardError, 'General error') do
      Wdpa::Portal::Managers::ViewManager.refresh_view_concurrently('test_view')
    end
  end

  test 'refresh_materialized_views handles errors from individual view refresh' do
    # Create test views
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_polygons AS
      SELECT 1 as wdpaid, 'test' as name, ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
    SQL

    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_points AS
      SELECT 1 as wdpaid, 'test' as name, ST_GeomFromText('POINT(0 0)') as wkb_geometry
    SQL

    # Mock the first refresh to succeed, second to fail
    Wdpa::Portal::Managers::ViewManager.expects(:refresh_view_concurrently).with('portal_standard_polygons')
    Wdpa::Portal::Managers::ViewManager.expects(:refresh_view_concurrently).with('portal_standard_points').raises(
      StandardError, 'Refresh failed'
    )

    assert_raises(StandardError, 'Refresh failed') do
      Wdpa::Portal::Managers::ViewManager.refresh_materialized_views
    end
  end

  test 'refresh_materialized_views with empty view list' do
    # Mock empty view list
    @config.stubs(:portal_materialised_view_values).returns([])
    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_materialised_view_values).returns([])

    # Should complete without error
    assert_nothing_raised do
      Wdpa::Portal::Managers::ViewManager.refresh_materialized_views
    end
  end

  test 'validate_required_views_exist with empty view list' do
    # Mock empty view list
    @config.stubs(:portal_materialised_view_values).returns([])
    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_materialised_view_values).returns([])

    result = Wdpa::Portal::Managers::ViewManager.validate_required_views_exist
    assert result
  end
end
