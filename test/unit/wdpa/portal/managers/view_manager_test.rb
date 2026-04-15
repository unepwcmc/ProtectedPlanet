require 'test_helper'

class Wdpa::Portal::Managers::ViewManagerTest < ActiveSupport::TestCase
  def setup
    @connection = ActiveRecord::Base.connection

    # Mock the configuration
    @config = mock('PortalImportConfig')
    @config.stubs(:portal_staging_materialised_view_values).returns(%w[portal_standard_polygons portal_standard_points
      portal_standard_sources])

    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_staging_materialised_view_values).returns(@config.portal_staging_materialised_view_values)
  end

  def teardown
    # Clean up any test views (CASCADE will also drop indexes)
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS portal_standard_polygons CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS portal_standard_points CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS portal_standard_sources CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS test_view CASCADE')
    
    # Clean up any orphaned indexes (if views were dropped without CASCADE)
    %w[idx_test_id idx_test_name staging_idx_test_id staging_idx_test_name staging_idx_existing staging_idx_new bk2501011200_idx_test_id bk2501011200_idx_test_name].each do |idx|
      @connection.execute("DROP INDEX IF EXISTS #{idx} CASCADE")
    end
  end

  test 'materialized_view_exists? returns true for existing view' do
    # Create a test materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW test_view AS
      SELECT 1 as id, 'test' as name
    SQL

    result = Wdpa::Portal::Managers::ViewManager.materialized_view_exists?('test_view')
    assert result
  end

  test 'materialized_view_exists? returns false for non-existent view' do
    result = Wdpa::Portal::Managers::ViewManager.materialized_view_exists?('non_existent_view')
    refute result
  end

  test 'validate_required_views_exist returns true when all views exist' do
    # Create all required views
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_polygons AS
      SELECT 1 as site_id, 'test' as name, ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
    SQL

    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW portal_standard_points AS
      SELECT 1 as site_id, 'test' as name, ST_GeomFromText('POINT(0 0)') as wkb_geometry
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
      SELECT 1 as site_id, 'test' as name, ST_GeomFromText('POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))') as wkb_geometry
    SQL

    result = Wdpa::Portal::Managers::ViewManager.validate_required_views_exist
    refute result
  end

  test 'validate_required_views_exist with empty view list' do
    # Mock empty view list
    @config.stubs(:portal_staging_materialised_view_values).returns([])
    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_staging_materialised_view_values).returns([])

    result = Wdpa::Portal::Managers::ViewManager.validate_required_views_exist
    assert result
  end

  test 'rename_materialised_view_indexes_add_staging_prefix adds staging prefix to indexes' do
    # Create test materialized view with indexes
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW test_view AS
      SELECT 1 as id, 'test' as name
    SQL
    
    @connection.execute('CREATE INDEX idx_test_id ON test_view (id)')
    @connection.execute('CREATE INDEX idx_test_name ON test_view (name)')
    
    # Rename indexes to add staging prefix
    Wdpa::Portal::Managers::ViewManager.rename_materialised_view_indexes_add_staging_prefix('test_view')
    
    # Verify indexes have staging prefix
    indexes = @connection.execute(<<~SQL).to_a
      SELECT indexname
      FROM pg_indexes
      WHERE schemaname = 'public' AND tablename = 'test_view'
      ORDER BY indexname
    SQL
    
    index_names = indexes.map { |row| row['indexname'] }
    assert_includes index_names, 'staging_idx_test_id'
    assert_includes index_names, 'staging_idx_test_name'
    refute_includes index_names, 'idx_test_id'
    refute_includes index_names, 'idx_test_name'
  end

  test 'rename_materialised_view_indexes_add_staging_prefix skips indexes that already have staging prefix' do
    # Create test materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW test_view AS
      SELECT 1 as id, 'test' as name
    SQL
    
    @connection.execute('CREATE INDEX staging_idx_existing ON test_view (id)')
    @connection.execute('CREATE INDEX idx_new ON test_view (name)')
    
    # Rename indexes
    Wdpa::Portal::Managers::ViewManager.rename_materialised_view_indexes_add_staging_prefix('test_view')
    
    # Verify existing staging prefix is not duplicated
    indexes = @connection.execute(<<~SQL).to_a
      SELECT indexname
      FROM pg_indexes
      WHERE schemaname = 'public' AND tablename = 'test_view'
      ORDER BY indexname
    SQL
    
    index_names = indexes.map { |row| row['indexname'] }
    assert_includes index_names, 'staging_idx_existing'  # Should remain unchanged
    assert_includes index_names, 'staging_idx_new'  # Should have prefix added
    refute_includes index_names, 'idx_new'
  end

  test 'rename_materialised_view_indexes_remove_backup_prefix removes backup prefix from indexes' do
    # Create test materialized view
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW test_view AS
      SELECT 1 as id, 'test' as name
    SQL
    
    @connection.execute('CREATE INDEX bk2501011200_idx_test_id ON test_view (id)')
    @connection.execute('CREATE INDEX bk2501011200_idx_test_name ON test_view (name)')
    
    # Remove backup prefix
    Wdpa::Portal::Managers::ViewManager.rename_materialised_view_indexes_remove_backup_prefix('test_view')
    
    # Verify backup prefix is removed
    indexes = @connection.execute(<<~SQL).to_a
      SELECT indexname
      FROM pg_indexes
      WHERE schemaname = 'public' AND tablename = 'test_view'
      ORDER BY indexname
    SQL
    
    index_names = indexes.map { |row| row['indexname'] }
    assert_includes index_names, 'idx_test_id'
    assert_includes index_names, 'idx_test_name'
    refute_includes index_names, 'bk2501011200_idx_test_id'
    refute_includes index_names, 'bk2501011200_idx_test_name'
  end

  test 'rename_materialised_view_indexes handles empty view' do
    # Create view without indexes
    @connection.execute(<<~SQL)
      CREATE MATERIALIZED VIEW test_view AS
      SELECT 1 as id
    SQL
    
    # Should not raise error
    assert_nothing_raised do
      Wdpa::Portal::Managers::ViewManager.rename_materialised_view_indexes_add_staging_prefix('test_view')
    end
  end
end
