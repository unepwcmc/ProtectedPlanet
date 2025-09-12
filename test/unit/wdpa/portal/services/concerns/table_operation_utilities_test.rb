require 'test_helper'

class Wdpa::Portal::Services::Concerns::TableOperationUtilitiesTest < ActiveSupport::TestCase
  def setup
    @connection = ActiveRecord::Base.connection
    @service = Class.new do
      include Wdpa::Portal::Services::Concerns::TableOperationUtilities

      def initialize
        @connection = ActiveRecord::Base.connection
        @index_cache = {}
      end
    end.new

    # Mock the configuration
    @config = mock('PortalImportConfig')
    @config.stubs(:lock_timeout_ms).returns(30_000)
    @config.stubs(:statement_timeout_ms).returns(300_000)
    @config.stubs(:staging_live_tables_hash).returns({
      'sources' => 'sources_staging',
      'protected_areas' => 'protected_areas_staging'
    })
    @config.stubs(:junction_tables).returns({ 'junction_table' => 'staging_junction' })
    @config.stubs(:generate_staging_table_index_name).returns { |name| "staging_#{name}" }

    Wdpa::Portal::Config::PortalImportConfig.stubs(:lock_timeout_ms).returns(@config.lock_timeout_ms)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:statement_timeout_ms).returns(@config.statement_timeout_ms)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:staging_live_tables_hash).returns(@config.staging_live_tables_hash)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:junction_tables).returns(@config.junction_tables)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:generate_staging_table_index_name).returns do |name|
      @config.generate_staging_table_index_name(name)
    end
  end

  def teardown
    # Clean up any test tables
    @connection.execute('DROP TABLE IF EXISTS test_table CASCADE')
    @connection.execute('DROP TABLE IF EXISTS sources CASCADE')
    @connection.execute('DROP TABLE IF EXISTS sources_staging CASCADE')
    @connection.execute('DROP SEQUENCE IF EXISTS test_seq CASCADE')
  end

  test 'setup_timeouts sets lock and statement timeouts' do
    @connection.expects(:execute).with('SET lock_timeout = 30000')
    @connection.expects(:execute).with('SET statement_timeout = 300000')

    @service.setup_timeouts(30_000, 300_000)

    assert_equal '30000', @service.instance_variable_get(:@original_lock_timeout)
    assert_equal '300000', @service.instance_variable_get(:@original_statement_timeout)
  end

  test 'restore_timeouts restores original timeout values' do
    @service.instance_variable_set(:@original_lock_timeout, '10000')
    @service.instance_variable_set(:@original_statement_timeout, '200000')

    @connection.expects(:execute).with("SET lock_timeout = '10000'")
    @connection.expects(:execute).with("SET statement_timeout = '200000'")

    @service.restore_timeouts
  end

  test 'restore_timeouts handles missing original values' do
    @service.instance_variable_set(:@original_lock_timeout, nil)
    @service.instance_variable_set(:@original_statement_timeout, nil)

    @connection.expects(:execute).with('SET lock_timeout = DEFAULT')
    @connection.expects(:execute).with('SET statement_timeout = DEFAULT')

    @service.restore_timeouts
  end

  test 'restore_timeouts handles errors gracefully' do
    @service.instance_variable_set(:@original_lock_timeout, '10000')
    @service.instance_variable_set(:@original_statement_timeout, '200000')

    @connection.expects(:execute).with("SET lock_timeout = '10000'").raises(StandardError, 'Connection error')

    # Should not raise error
    assert_nothing_raised do
      @service.restore_timeouts
    end
  end

  test 'get_table_indexes returns indexes for table' do
    # Create a table with indexes
    @connection.execute('CREATE TABLE test_table (id SERIAL PRIMARY KEY, name VARCHAR, email VARCHAR)')
    @connection.execute('CREATE INDEX idx_name ON test_table (name)')
    @connection.execute('CREATE UNIQUE INDEX idx_email ON test_table (email)')

    result = @service.get_table_indexes('test_table')

    # Should return non-primary key indexes
    index_names = result.map { |idx| idx[:name] }
    assert_includes index_names, 'idx_name'
    assert_includes index_names, 'idx_email'
    refute_includes index_names, 'test_table_pkey'
  end

  test 'get_table_indexes caches results' do
    # Create a table with an index
    @connection.execute('CREATE TABLE test_table (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE INDEX idx_name ON test_table (name)')

    # First call should query database
    @connection.expects(:execute).once.returns([{ 'indexname' => 'idx_name',
                                                  'indexdef' => 'CREATE INDEX idx_name ON test_table (name)' }])

    result1 = @service.get_table_indexes('test_table')
    result2 = @service.get_table_indexes('test_table')

    assert_equal result1, result2
  end

  test 'get_table_sequences returns sequences for table' do
    # Create a table with a sequence
    @connection.execute('CREATE TABLE test_table (id SERIAL PRIMARY KEY, name VARCHAR)')

    result = @service.get_table_sequences('test_table')

    # Should find the sequence
    sequence_names = result.map { |seq| seq[:name] }
    assert_includes sequence_names, 'test_table_id_seq'
  end

  test 'get_table_sequences handles tables without sequences' do
    # Create a table without a sequence (junction table)
    @connection.execute('CREATE TABLE test_table (id INTEGER, name VARCHAR)')

    result = @service.get_table_sequences('test_table')

    assert_equal [], result
  end

  test 'rename_database_object renames index' do
    # Create a table with an index
    @connection.execute('CREATE TABLE test_table (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE INDEX old_idx ON test_table (name)')

    @connection.expects(:execute).with('ALTER INDEX old_idx RENAME TO new_idx')

    @service.rename_database_object('index', 'test_table', 'old_idx', 'new_idx')
  end

  test 'rename_database_object renames constraint' do
    @connection.expects(:execute).with('ALTER TABLE test_table RENAME CONSTRAINT old_constraint TO new_constraint')

    @service.rename_database_object('constraint', 'test_table', 'old_constraint', 'new_constraint')
  end

  test 'rename_database_object renames sequence' do
    @connection.expects(:execute).with('ALTER SEQUENCE old_seq RENAME TO new_seq')

    @service.rename_database_object('sequence', 'test_table', 'old_seq', 'new_seq')
  end

  test 'rename_database_object skips when old and new names are same' do
    @connection.expects(:execute).never

    @service.rename_database_object('index', 'test_table', 'same_name', 'same_name')
  end

  test 'validate_staging_table validates primary key compatibility' do
    # Create source and staging tables
    @connection.execute('CREATE TABLE sources (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE TABLE sources_staging (id SERIAL PRIMARY KEY, name VARCHAR)')

    # Mock the primary key names
    @service.expects(:get_primary_key_name).with('sources').returns('sources_pkey')
    @service.expects(:get_primary_key_name).with('sources_staging').returns('staging_sources_pkey')

    result = @service.validate_staging_table('sources_staging')
    assert result
  end

  test 'validate_staging_table skips validation for junction tables' do
    result = @service.validate_staging_table('staging_junction')
    assert result
  end

  test 'validate_staging_live_table_primary_key validates primary key names' do
    @service.expects(:get_primary_key_name).with('sources').returns('sources_pkey')
    @service.expects(:get_primary_key_name).with('sources_staging').returns('staging_sources_pkey')

    result = @service.validate_staging_live_table_primary_key('sources_staging', 'sources')
    assert result
  end

  test 'validate_staging_live_table_primary_key raises error for missing primary keys' do
    @service.expects(:get_primary_key_name).with('sources').returns(nil)
    @service.expects(:get_primary_key_name).with('sources_staging').returns('staging_sources_pkey')

    assert_raises(RuntimeError, /Primary key mismatch/) do
      @service.validate_staging_live_table_primary_key('sources_staging', 'sources')
    end
  end

  test 'validate_staging_live_table_primary_key raises error for name mismatch' do
    @service.expects(:get_primary_key_name).with('sources').returns('sources_pkey')
    @service.expects(:get_primary_key_name).with('sources_staging').returns('wrong_name')

    assert_raises(RuntimeError, /Primary key name mismatch/) do
      @service.validate_staging_live_table_primary_key('sources_staging', 'sources')
    end
  end

  test 'junction_table? returns true for junction tables' do
    result = @service.junction_table?('staging_junction')
    assert result
  end

  test 'junction_table? returns false for non-junction tables' do
    result = @service.junction_table?('sources_staging')
    refute result
  end

  test 'execute_with_error_handling executes SQL successfully' do
    @connection.expects(:execute).with('SELECT 1')

    @service.execute_with_error_handling('SELECT 1', 'Success message')
  end

  test 'execute_with_error_handling handles errors gracefully' do
    @connection.expects(:execute).with('INVALID SQL').raises(StandardError, 'SQL error')

    # Should not raise error
    assert_nothing_raised do
      @service.execute_with_error_handling('INVALID SQL', 'Success message', 'Custom error')
    end
  end

  test 'get_current_setting retrieves database setting' do
    @connection.expects(:execute).with('SHOW lock_timeout').returns([{ 'lock_timeout' => '30000' }])

    result = @service.get_current_setting('lock_timeout')
    assert_equal '30000', result
  end

  test 'all_table_names returns all live table names' do
    result = @service.all_table_names
    expected = %w[sources protected_areas]
    assert_equal expected, result
  end

  test 'clear_index_cache clears specific table cache' do
    @service.instance_variable_set(:@index_cache, { 'test_table' => [{ name: 'idx1' }] })

    @service.clear_index_cache('test_table')

    assert_nil @service.instance_variable_get(:@index_cache)['test_table']
  end

  test 'clear_index_cache clears all cache when no table specified' do
    @service.instance_variable_set(:@index_cache, { 'table1' => [], 'table2' => [] })

    @service.clear_index_cache

    assert_empty @service.instance_variable_get(:@index_cache)
  end

  test 'index_exists? checks for index existence' do
    # Create a table with an index
    @connection.execute('CREATE TABLE test_table (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE INDEX test_idx ON test_table (name)')

    result = @service.index_exists?('test_idx')
    assert result

    result = @service.index_exists?('non_existent_idx')
    refute result
  end

  test 'sequence_exists? checks for sequence existence' do
    # Create a sequence
    @connection.execute('CREATE SEQUENCE test_seq')

    result = @service.sequence_exists?('test_seq')
    assert result

    result = @service.sequence_exists?('non_existent_seq')
    refute result
  end

  test 'generate_unique_index_name returns candidate name when available' do
    @service.expects(:index_exists?).with('candidate_name').returns(false)

    result = @service.generate_unique_index_name('candidate_name')
    assert_equal 'candidate_name', result
  end

  test 'generate_unique_index_name generates random name when candidate exists' do
    @service.expects(:index_exists?).with('candidate_name').returns(true)
    @service.expects(:index_exists?).with('idx_abc123').returns(false)

    # Mock SecureRandom.hex to return predictable value
    SecureRandom.expects(:hex).with(4).returns('abc123')

    result = @service.generate_unique_index_name('candidate_name')
    assert_equal 'idx_abc123', result
  end

  test 'parse_backup_timestamp parses YYMMDDHHMM format' do
    result = @service.parse_backup_timestamp('2501011200')
    expected = Time.new(2025, 1, 1, 12, 0, 0)
    assert_equal expected, result
  end

  test 'parse_backup_timestamp returns nil for invalid format' do
    result = @service.parse_backup_timestamp('invalid')
    assert_nil result
  end

  test 'get_primary_key_name returns primary key name' do
    # Create a table with primary key
    @connection.execute('CREATE TABLE test_table (id SERIAL PRIMARY KEY, name VARCHAR)')

    result = @service.get_primary_key_name('test_table')
    assert_equal 'test_table_pkey', result
  end

  test 'get_primary_key_name returns nil for table without primary key' do
    # Create a table without primary key
    @connection.execute('CREATE TABLE test_table (id INTEGER, name VARCHAR)')

    result = @service.get_primary_key_name('test_table')
    assert_nil result
  end

  test 'find_matching_backup finds matching index by structure' do
    live_index = { name: 'idx_live', definition: 'CREATE INDEX idx_live ON table (name, email)' }
    backup_indexes = [
      { name: 'idx_backup1', definition: 'CREATE INDEX idx_backup1 ON table (name, email)' },
      { name: 'idx_backup2', definition: 'CREATE INDEX idx_backup2 ON table (other_col)' }
    ]

    result = @service.find_matching_backup(live_index, backup_indexes)

    assert_equal backup_indexes[0], result
  end

  test 'find_matching_backup handles unique indexes' do
    live_index = { name: 'idx_live', definition: 'CREATE UNIQUE INDEX idx_live ON table (email)' }
    backup_indexes = [
      { name: 'idx_backup1', definition: 'CREATE INDEX idx_backup1 ON table (email)' },
      { name: 'idx_backup2', definition: 'CREATE UNIQUE INDEX idx_backup2 ON table (email)' }
    ]

    result = @service.find_matching_backup(live_index, backup_indexes)

    assert_equal backup_indexes[1], result
  end

  test 'extract_columns_from_index extracts column names from index definition' do
    definition = 'CREATE INDEX idx_name ON table (name, email, created_at)'

    result = @service.extract_columns_from_index(definition)

    expected = %w[name email created_at]
    assert_equal expected, result
  end

  test 'extract_columns_from_index handles complex expressions' do
    definition = 'CREATE INDEX idx_name ON table (LOWER(name), UPPER(email), "created_at" DESC)'

    result = @service.extract_columns_from_index(definition)

    expected = ['LOWER(name)', 'UPPER(email)', '"created_at" DESC']
    assert_equal expected, result
  end

  test 'extract_columns_from_index returns empty array for invalid definition' do
    definition = 'INVALID INDEX DEFINITION'

    result = @service.extract_columns_from_index(definition)

    assert_equal [], result
  end
end
