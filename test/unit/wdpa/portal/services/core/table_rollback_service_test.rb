require 'test_helper'

class Wdpa::Portal::Services::Core::TableRollbackServiceTest < ActiveSupport::TestCase
  def setup
    @connection = ActiveRecord::Base.connection
    @service = Wdpa::Portal::Services::Core::TableRollbackService.new
    @backup_timestamp = '2501011200'
    
    # Mock the configuration
    @config = mock('PortalImportConfig')
    @config.stubs(:staging_live_tables_hash).returns({
      'sources' => 'sources_staging',
      'protected_areas' => 'protected_areas_staging'
    })
    @config.stubs(:swap_sequence_live_table_names).returns(['sources', 'protected_areas'])
    @config.stubs(:lock_timeout_ms).returns(30000)
    @config.stubs(:statement_timeout_ms).returns(300000)
    @config.stubs(:generate_backup_name).returns { |table, timestamp| "bk#{timestamp}_#{table}" }
    @config.stubs(:generate_staging_table_index_name).returns { |name| "staging_#{name}" }
    @config.stubs(:remove_backup_suffix).returns { |name| name.gsub(/^bk\d{10}_/, '') }
    
    Wdpa::Portal::Config::PortalImportConfig.stubs(:staging_live_tables_hash).returns(@config.staging_live_tables_hash)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:swap_sequence_live_table_names).returns(@config.swap_sequence_live_table_names)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:lock_timeout_ms).returns(@config.lock_timeout_ms)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:statement_timeout_ms).returns(@config.statement_timeout_ms)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:generate_backup_name).returns { |table, timestamp| @config.generate_backup_name(table, timestamp) }
    Wdpa::Portal::Config::PortalImportConfig.stubs(:generate_staging_table_index_name).returns { |name| @config.generate_staging_table_index_name(name) }
    Wdpa::Portal::Config::PortalImportConfig.stubs(:remove_backup_suffix).returns { |name| @config.remove_backup_suffix(name) }
  end

  def teardown
    # Clean up any test tables
    @connection.execute('DROP TABLE IF EXISTS sources CASCADE')
    @connection.execute('DROP TABLE IF EXISTS sources_staging CASCADE')
    @connection.execute('DROP TABLE IF EXISTS protected_areas CASCADE')
    @connection.execute('DROP TABLE IF EXISTS protected_areas_staging CASCADE')
    @connection.execute('DROP TABLE IF EXISTS bk2501011200_sources CASCADE')
    @connection.execute('DROP TABLE IF EXISTS bk2501011200_protected_areas CASCADE')
    
    # Clean up any test materialized views
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS portal_standard_polygons CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS staging_portal_standard_polygons CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS bk2501011200_portal_standard_polygons CASCADE')
  end

  test 'initializes rollback variables correctly' do
    @service.initialize_rollback_variables(@backup_timestamp)
    
    assert_equal @backup_timestamp, @service.instance_variable_get(:@backup_timestamp)
    assert_equal [], @service.instance_variable_get(:@swapped_tables)
    assert_equal @connection, @service.instance_variable_get(:@connection)
    assert_equal({}, @service.instance_variable_get(:@index_cache))
  end

  test 'prepares for rollback by setting timeouts' do
    @service.initialize_rollback_variables(@backup_timestamp)
    @service.expects(:setup_timeouts).with(30000, 300000)
    @service.prepare_for_rollback
  end


  test 'raises error when backup tables are missing' do
    @service.initialize_rollback_variables(@backup_timestamp)
    
    # Don't create backup tables
    assert_raises(RuntimeError, /Missing backup tables/) do
      @service.validate_backup_tables_exist
    end
  end


  test 'rollback_single_table handles missing live table' do
    @service.initialize_rollback_variables(@backup_timestamp)
    
    # Create only backup table
    @connection.execute('CREATE TABLE bk2501011200_sources (id SERIAL PRIMARY KEY, name VARCHAR)')
    
    # Mock database object processing
    @service.expects(:process_database_objects_after_rollback).with('sources', 'sources_staging')
    
    @service.rollback_single_table('sources', 'bk2501011200_sources', 'sources_staging')
    
    # Verify backup was restored to live
    assert @connection.table_exists?('sources')
    refute @connection.table_exists?('bk2501011200_sources')
  end

  test 'process_database_objects_after_rollback calls all required methods' do
    @service.initialize_rollback_variables(@backup_timestamp)
    
    @service.expects(:rename_primary_keys_after_rollback).with('sources', 'sources_staging')
    @service.expects(:rename_indexes_after_rollback).with('sources', 'sources_staging')
    @service.expects(:rename_sequences_after_rollback).with('sources', 'sources_staging')
    
    @service.process_database_objects_after_rollback('sources', 'sources_staging')
  end


  test 'rename_primary_keys_after_rollback returns early when no primary keys' do
    @service.initialize_rollback_variables(@backup_timestamp)
    
    @service.expects(:get_primary_key_name).with('sources').returns(nil)
    @service.expects(:get_primary_key_name).with('sources_staging').returns(nil)
    
    @service.expects(:rename_database_object).never
    
    @service.rename_primary_keys_after_rollback('sources', 'sources_staging')
  end

  test 'list_available_backups_impl returns sorted timestamps' do
    @service.initialize_rollback_variables(nil)
    
    # Create test backup tables
    @connection.execute('CREATE TABLE bk2501011200_sources (id SERIAL PRIMARY KEY)')
    @connection.execute('CREATE TABLE bk2501011201_sources (id SERIAL PRIMARY KEY)')
    @connection.execute('CREATE TABLE bk2501011202_sources (id SERIAL PRIMARY KEY)')
    @connection.execute('CREATE TABLE regular_table (id SERIAL PRIMARY KEY)')
    
    # Mock table listing
    @connection.expects(:tables).returns([
      'bk2501011200_sources', 'bk2501011201_sources', 'bk2501011202_sources', 'regular_table'
    ])
    
    result = @service.list_available_backups_impl
    
    # Should return timestamps in reverse chronological order
    expected = ['2501011202', '2501011201', '2501011200']
    assert_equal expected, result
  end

  test 'restore_after_rollback restores timeouts' do
    @service.initialize_rollback_variables(@backup_timestamp)
    @service.expects(:restore_timeouts)
    @service.restore_after_rollback
  end

  test 'list_available_backups runs list workflow' do
    service_instance = mock('service_instance')
    Wdpa::Portal::Services::Core::TableRollbackService.expects(:new).returns(service_instance)
    
    service_instance.expects(:initialize_rollback_variables).with(nil)
    service_instance.expects(:list_available_backups_impl).returns(['2501011200', '2501011201'])
    
    result = Wdpa::Portal::Services::Core::TableRollbackService.list_available_backups
    assert_equal ['2501011200', '2501011201'], result
  end

  test 'rollback_portal_materialized_views handles errors gracefully' do
    @service.initialize_rollback_variables(@backup_timestamp)
    
    @config.stubs(:portal_live_materialised_view_values).returns(['portal_standard_polygons'])
    @config.stubs(:get_staging_materialised_view_name_from_live).with('portal_standard_polygons').returns('staging_portal_standard_polygons')
    @config.stubs(:generate_backup_name).with('portal_standard_polygons', @backup_timestamp).returns("bk#{@backup_timestamp}_portal_standard_polygons")
    
    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_live_materialised_view_values).returns(@config.portal_live_materialised_view_values)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:get_staging_materialised_view_name_from_live).returns { |name| @config.get_staging_materialised_view_name_from_live(name) }
    Wdpa::Portal::Config::PortalImportConfig.stubs(:generate_backup_name).returns { |name, ts| @config.generate_backup_name(name, ts) }
    
    # Mock ViewManager to raise error
    Wdpa::Portal::Managers::ViewManager.stubs(:materialized_view_exists?).raises(StandardError, 'Database error')
    
    # Should not raise, but log warning
    assert_nothing_raised do
      @service.rollback_portal_materialized_views
    end
  end
end
