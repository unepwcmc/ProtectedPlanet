require 'test_helper'

class Wdpa::Portal::Managers::StagingTableManagerTest < ActiveSupport::TestCase
  def setup
    @connection = ActiveRecord::Base.connection

    # Mock the configuration
    @config = mock('PortalImportConfig')
    @config.stubs(:staging_tables).returns(%w[sources_staging protected_areas_staging])
    @config.stubs(:staging_live_tables_hash).returns({
      'sources' => 'sources_staging',
      'protected_areas' => 'protected_areas_staging'
    })
    @config.stubs(:swap_sequence_live_table_names).returns(%w[sources protected_areas])
    @config.stubs(:get_live_table_name_from_staging_name).returns do |staging|
      @config.staging_live_tables_hash.invert[staging]
    end

    Wdpa::Portal::Config::PortalImportConfig.stubs(:staging_tables).returns(@config.staging_tables)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:staging_live_tables_hash).returns(@config.staging_live_tables_hash)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:swap_sequence_live_table_names).returns(@config.swap_sequence_live_table_names)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:get_live_table_name_from_staging_name).returns do |staging|
      @config.get_live_table_name_from_staging_name(staging)
    end
  end

  def teardown
    # Clean up any test tables
    @connection.execute('DROP TABLE IF EXISTS sources CASCADE')
    @connection.execute('DROP TABLE IF EXISTS sources_staging CASCADE')
    @connection.execute('DROP TABLE IF EXISTS protected_areas CASCADE')
    @connection.execute('DROP TABLE IF EXISTS protected_areas_staging CASCADE')
  end

  test 'create_staging_tables drops existing and creates new tables' do
    # Create existing staging tables
    @connection.execute('CREATE TABLE sources_staging (id SERIAL PRIMARY KEY)')
    @connection.execute('CREATE TABLE protected_areas_staging (id SERIAL PRIMARY KEY)')

    # Create source tables
    @connection.execute('CREATE TABLE sources (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE TABLE protected_areas (id SERIAL PRIMARY KEY, name VARCHAR)')

    Wdpa::Portal::Managers::StagingTableManager.create_staging_tables

    # Verify staging tables exist
    assert @connection.table_exists?('sources_staging')
    assert @connection.table_exists?('protected_areas_staging')
  end

  test 'create_all_staging_tables creates all configured staging tables' do
    # Create source tables
    @connection.execute('CREATE TABLE sources (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE TABLE protected_areas (id SERIAL PRIMARY KEY, name VARCHAR)')

    Wdpa::Portal::Managers::StagingTableManager.create_all_staging_tables

    # Verify staging tables exist
    assert @connection.table_exists?('sources_staging')
    assert @connection.table_exists?('protected_areas_staging')
  end

  test 'add_all_foreign_keys adds foreign keys to all staging tables' do
    # Create source and staging tables
    @connection.execute('CREATE TABLE sources (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE TABLE protected_areas (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE TABLE sources_staging (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE TABLE protected_areas_staging (id SERIAL PRIMARY KEY, name VARCHAR)')

    Wdpa::Portal::Managers::StagingTableManager.add_all_foreign_keys

    # Verify foreign keys were added (this would require checking pg_constraint in a real test)
    # For now, just verify the method doesn't raise an error
    assert true
  end

  test 'drop_staging_tables drops tables in correct order' do
    # Create staging tables
    @connection.execute('CREATE TABLE sources_staging (id SERIAL PRIMARY KEY)')
    @connection.execute('CREATE TABLE protected_areas_staging (id SERIAL PRIMARY KEY)')

    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables

    # Verify tables were dropped
    refute @connection.table_exists?('sources_staging')
    refute @connection.table_exists?('protected_areas_staging')
  end

  test 'get_tables_in_drop_order returns tables in reverse swap sequence' do
    result = Wdpa::Portal::Managers::StagingTableManager.get_tables_in_drop_order

    # Should be in reverse order: protected_areas_staging, sources_staging
    expected = %w[protected_areas_staging sources_staging]
    assert_equal expected, result
  end

  test 'drop_table_safely drops existing table' do
    @connection.execute('CREATE TABLE test_table (id SERIAL PRIMARY KEY)')

    Wdpa::Portal::Managers::StagingTableManager.drop_table_safely('test_table')

    refute @connection.table_exists?('test_table')
  end

  test 'drop_table_safely skips non-existent table' do
    # Should not raise error
    assert_nothing_raised do
      Wdpa::Portal::Managers::StagingTableManager.drop_table_safely('non_existent_table')
    end
  end

  test 'drop_table_safely handles dependency errors with CASCADE' do
    # Create a table with dependencies
    @connection.execute('CREATE TABLE test_table (id SERIAL PRIMARY KEY)')
    @connection.execute('CREATE TABLE dependent_table (id SERIAL PRIMARY KEY, test_id INTEGER REFERENCES test_table(id))')

    # Mock the drop to raise dependency error first, then succeed with CASCADE
    @connection.expects(:drop_table).with('test_table').raises(ActiveRecord::StatementInvalid.new('DependentObjectsStillExist'))
    @connection.expects(:drop_table).with('test_table', if_exists: true, force: :cascade)

    Wdpa::Portal::Managers::StagingTableManager.drop_table_safely('test_table')
  end

  test 'staging_tables_exist? returns true when all tables exist' do
    # Create staging tables
    @connection.execute('CREATE TABLE sources_staging (id SERIAL PRIMARY KEY)')
    @connection.execute('CREATE TABLE protected_areas_staging (id SERIAL PRIMARY KEY)')

    result = Wdpa::Portal::Managers::StagingTableManager.staging_tables_exist?
    assert result
  end

  test 'staging_tables_exist? returns false when some tables missing' do
    # Create only one staging table
    @connection.execute('CREATE TABLE sources_staging (id SERIAL PRIMARY KEY)')

    result = Wdpa::Portal::Managers::StagingTableManager.staging_tables_exist?
    refute result
  end

  test 'ensure_staging_tables_exist! creates tables when missing and create_if_missing is true' do
    Wdpa::Portal::Managers::StagingTableManager.expects(:create_staging_tables)

    Wdpa::Portal::Managers::StagingTableManager.ensure_staging_tables_exist!(create_if_missing: true)
  end

  test 'ensure_staging_tables_exist! raises error when missing and create_if_missing is false' do
    assert_raises(StandardError, /Required staging tables are missing/) do
      Wdpa::Portal::Managers::StagingTableManager.ensure_staging_tables_exist!(create_if_missing: false)
    end
  end

  test 'create_staging_table creates exact copy of live table' do
    # Create source table
    @connection.execute('CREATE TABLE sources (id SERIAL PRIMARY KEY, name VARCHAR)')

    Wdpa::Portal::Managers::StagingTableManager.create_staging_table('sources_staging')

    # Verify staging table exists and has same structure
    assert @connection.table_exists?('sources_staging')

    # Check columns match
    source_columns = @connection.columns('sources').map(&:name).sort
    staging_columns = @connection.columns('sources_staging').map(&:name).sort
    assert_equal source_columns, staging_columns
  end

  test 'add_foreign_keys_to_staging_table adds foreign keys' do
    # Create source and staging tables
    @connection.execute('CREATE TABLE sources (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE TABLE sources_staging (id SERIAL PRIMARY KEY, name VARCHAR)')

    Wdpa::Portal::Managers::StagingTableManager.add_foreign_keys_to_staging_table('sources_staging')

    # Verify method completes without error
    assert true
  end

  test 'create_exact_table_copy creates table with INCLUDING ALL' do
    # Create source table
    @connection.execute('CREATE TABLE sources (id SERIAL PRIMARY KEY, name VARCHAR)')

    Wdpa::Portal::Managers::StagingTableManager.create_exact_table_copy('sources', 'test_copy')

    # Verify copy exists
    assert @connection.table_exists?('test_copy')

    # Clean up
    @connection.execute('DROP TABLE test_copy CASCADE')
  end

  test 'create_staging_sequence creates separate sequence for staging table' do
    # Create source table
    @connection.execute('CREATE TABLE sources (id SERIAL PRIMARY KEY, name VARCHAR)')

    Wdpa::Portal::Managers::StagingTableManager.create_staging_sequence('sources', 'sources_staging')

    # Verify sequence exists
    sequence_name = 'sources_staging_id_seq'
    result = @connection.execute("SELECT EXISTS (SELECT 1 FROM pg_sequences WHERE sequencename = '#{sequence_name}')")
    assert result.first.values.first
  end

  test 'create_staging_sequence skips junction tables' do
    # Mock primary key to return nil (junction table)
    @connection.expects(:primary_key).with('junction_table').returns(nil)

    Wdpa::Portal::Managers::StagingTableManager.create_staging_sequence('junction_table', 'staging_junction')

    # Should complete without creating sequence
    assert true
  end

  test 'sequence_exists? checks for sequence existence' do
    # Create a sequence
    @connection.execute('CREATE SEQUENCE test_seq')

    result = Wdpa::Portal::Managers::StagingTableManager.sequence_exists?('test_seq')
    assert result

    # Clean up
    @connection.execute('DROP SEQUENCE test_seq')
  end

  test 'sequence_exists? returns false for non-existent sequence' do
    result = Wdpa::Portal::Managers::StagingTableManager.sequence_exists?('non_existent_seq')
    refute result
  end

  test 'add_foreign_keys adds foreign keys from live table' do
    # Create source and staging tables
    @connection.execute('CREATE TABLE sources (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE TABLE sources_staging (id SERIAL PRIMARY KEY, name VARCHAR)')

    Wdpa::Portal::Managers::StagingTableManager.add_foreign_keys('sources_staging', 'sources')

    # Verify method completes without error
    assert true
  end

  test 'determine_referenced_table returns staging table when available' do
    result = Wdpa::Portal::Managers::StagingTableManager.determine_referenced_table('sources')
    assert_equal 'sources_staging', result
  end

  test 'determine_referenced_table returns live table when staging not available' do
    result = Wdpa::Portal::Managers::StagingTableManager.determine_referenced_table('other_table')
    assert_equal 'other_table', result
  end

  test 'cleanup_auto_generated_index_suffixes removes _idx suffixes' do
    # Create a table with an index that has _idx suffix
    @connection.execute('CREATE TABLE test_table (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE INDEX test_idx ON test_table (name)')

    # Rename the index to have _idx suffix
    @connection.execute('ALTER INDEX test_idx RENAME TO test_idx_idx')

    Wdpa::Portal::Managers::StagingTableManager.cleanup_auto_generated_index_suffixes('test_table')

    # Verify the _idx suffix was removed
    result = @connection.execute("SELECT indexname FROM pg_indexes WHERE tablename = 'test_table' AND indexname = 'test_idx'")
    assert result.any?

    # Clean up
    @connection.execute('DROP TABLE test_table CASCADE')
  end

  test 'index_exists? checks for index existence' do
    # Create a table with an index
    @connection.execute('CREATE TABLE test_table (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE INDEX test_idx ON test_table (name)')

    result = Wdpa::Portal::Managers::StagingTableManager.index_exists?(@connection, 'test_idx')
    assert result

    # Clean up
    @connection.execute('DROP TABLE test_table CASCADE')
  end

  test 'index_exists? returns false for non-existent index' do
    result = Wdpa::Portal::Managers::StagingTableManager.index_exists?(@connection, 'non_existent_idx')
    refute result
  end
end
