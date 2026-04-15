require 'test_helper'

class Wdpa::Portal::Services::Core::TableSwapServiceTest < ActiveSupport::TestCase
  def setup
    @connection = ActiveRecord::Base.connection
    @service = Wdpa::Portal::Services::Core::TableSwapService.new
    @backup_timestamp = '2501011200'

    # Mock the configuration
    @config = mock('PortalImportConfig')
    @config.stubs(:staging_live_tables_hash).returns({
      'sources' => 'sources_staging',
      'protected_areas' => 'protected_areas_staging'
    })
    @config.stubs(:swap_sequence_live_table_names).returns(%w[sources protected_areas])
    @config.stubs(:lock_timeout_ms).returns(30_000)
    @config.stubs(:statement_timeout_ms).returns(300_000)
    @config.stubs(:generate_backup_name).with('sources', @backup_timestamp).returns("bk#{@backup_timestamp}_sources")
    @config.stubs(:generate_backup_name).with('protected_areas',
      @backup_timestamp).returns("bk#{@backup_timestamp}_protected_areas")

    Wdpa::Portal::Config::PortalImportConfig.stubs(:staging_live_tables_hash).returns(@config.staging_live_tables_hash)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:swap_sequence_live_table_names).returns(@config.swap_sequence_live_table_names)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:lock_timeout_ms).returns(@config.lock_timeout_ms)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:statement_timeout_ms).returns(@config.statement_timeout_ms)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:generate_backup_name).returns do |table, timestamp|
      "bk#{timestamp}_#{table}"
    end
  end

  def teardown
    # Clean up any test tables
    @connection.execute('DROP TABLE IF EXISTS sources_staging CASCADE')
    @connection.execute('DROP TABLE IF EXISTS protected_areas_staging CASCADE')
    @connection.execute('DROP TABLE IF EXISTS bk2501011200_sources CASCADE')
    @connection.execute('DROP TABLE IF EXISTS bk2501011200_protected_areas CASCADE')
  end

  test 'initializes swap variables correctly' do
    @service.initialize_swap_variables

    assert_not_nil @service.instance_variable_get(:@backup_timestamp)
    assert_equal [], @service.instance_variable_get(:@swapped_tables)
    assert_equal @connection, @service.instance_variable_get(:@connection)
    assert_equal({}, @service.instance_variable_get(:@index_cache))
  end

  test 'prepares for swap by setting timeouts' do
    @service.initialize_swap_variables
    @service.expects(:setup_timeouts).with(30_000, 300_000)
    @service.prepare_for_swap
  end

  test 'validates staging tables existence' do
    @service.initialize_swap_variables

    # Create test staging tables
    @connection.execute('CREATE TABLE sources_staging (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE TABLE protected_areas_staging (id SERIAL PRIMARY KEY, name VARCHAR)')

    # Should not raise error when all staging tables exist
    assert_nothing_raised do
      @service.validate_staging_tables_existence
    end
  end

  test 'raises error when staging tables are missing' do
    @service.initialize_swap_variables

    # Don't create staging tables
    assert_raises(RuntimeError, /Missing staging tables/) do
      @service.validate_staging_tables_existence
    end
  end

  test 'process_database_objects_after_swap calls all required methods' do
    @service.initialize_swap_variables

    @service.expects(:rename_primary_keys_after_swap).with('sources', 'bk2501011200_sources')
    @service.expects(:rename_indexes_after_swap).with('sources', 'bk2501011200_sources')
    @service.expects(:rename_sequences_after_swap).with('sources', 'bk2501011200_sources')

    @service.process_database_objects_after_swap('sources', 'bk2501011200_sources')
  end

  test 'rename_primary_keys_after_swap returns early when no primary keys' do
    @service.initialize_swap_variables

    @service.expects(:get_primary_key_name).with('sources').returns(nil)
    @service.expects(:get_primary_key_name).with('bk2501011200_sources').returns(nil)

    @service.expects(:rename_database_object).never

    @service.rename_primary_keys_after_swap('sources', 'bk2501011200_sources')
  end

  test 'rename_indexes_after_swap processes indexes correctly' do
    @service.initialize_swap_variables

    # Mock index data
    live_indexes = [{ name: 'idx_live', definition: 'CREATE INDEX idx_live ON sources (name)' }]
    backup_indexes = [{ name: 'idx_backup', definition: 'CREATE INDEX idx_backup ON sources (name)' }]

    @service.expects(:get_table_indexes).with('sources').returns(live_indexes)
    @service.expects(:get_table_indexes).with('bk2501011200_sources').returns(backup_indexes)
    @service.expects(:find_matching_backup).with(live_indexes[0], backup_indexes).returns(backup_indexes[0])
    @service.expects(:generate_unique_index_name).returns('idx_unique')
    @service.expects(:rename_database_object).with('index', 'bk2501011200_sources', 'idx_backup', 'idx_unique')
    @service.expects(:rename_database_object).with('index', 'sources', 'idx_live', 'idx_backup')

    @service.rename_indexes_after_swap('sources', 'bk2501011200_sources')
  end

  test 'restore_after_swap restores timeouts' do
    @service.initialize_swap_variables
    @service.expects(:restore_timeouts)
    @service.restore_after_swap
  end
end
