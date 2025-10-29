require 'test_helper'

class Wdpa::Portal::Services::Core::TableCleanupServiceTest < ActiveSupport::TestCase
  def setup
    @connection = ActiveRecord::Base.connection
    @service = Wdpa::Portal::Services::Core::TableCleanupService.new
    
    # Mock the configuration
    @config = mock('PortalImportConfig')
    @config.stubs(:swap_sequence_live_table_names).returns(['sources', 'protected_areas'])
    @config.stubs(:lock_timeout_ms).returns(30000)
    @config.stubs(:statement_timeout_ms).returns(300000)
    @config.stubs(:keep_backup_count).returns(2)
    @config.stubs(:is_backup_table?).returns { |table| table.start_with?('bk') }
    @config.stubs(:extract_backup_timestamp).returns { |table| table.match(/bk(\d{10})_/)[1] if table.match(/bk(\d{10})_/) }
    @config.stubs(:extract_table_name_from_backup).returns { |table| table.gsub(/^bk\d{10}_/, '') }
    @config.stubs(:junction_tables).returns({})
    @config.stubs(:main_entity_tables).returns({})
    @config.stubs(:independent_table_names).returns({})
    
    Wdpa::Portal::Config::PortalImportConfig.stubs(:swap_sequence_live_table_names).returns(@config.swap_sequence_live_table_names)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:lock_timeout_ms).returns(@config.lock_timeout_ms)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:statement_timeout_ms).returns(@config.statement_timeout_ms)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:keep_backup_count).returns(@config.keep_backup_count)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:is_backup_table?).returns { |table| @config.is_backup_table?(table) }
    Wdpa::Portal::Config::PortalImportConfig.stubs(:extract_backup_timestamp).returns { |table| @config.extract_backup_timestamp(table) }
    Wdpa::Portal::Config::PortalImportConfig.stubs(:extract_table_name_from_backup).returns { |table| @config.extract_table_name_from_backup(table) }
    Wdpa::Portal::Config::PortalImportConfig.stubs(:junction_tables).returns(@config.junction_tables)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:main_entity_tables).returns(@config.main_entity_tables)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:independent_table_names).returns(@config.independent_table_names)
    
    # Mock live materialized views
    @config.stubs(:portal_live_materialised_view_values).returns(['portal_standard_polygons', 'portal_standard_points'])
    @config.stubs(:PORTAL_DOWNALOAD_VIEWS).returns('portal_downloads_protected_areas')
    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_live_materialised_view_values).returns(@config.portal_live_materialised_view_values)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:PORTAL_DOWNALOAD_VIEWS).returns(@config.PORTAL_DOWNALOAD_VIEWS)
    Wdpa::Portal::Config::PortalImportConfig.stubs(:generate_backup_name).returns { |name, timestamp| "bk#{timestamp}_#{name}" }
  end

  def teardown
    # Clean up any test tables
    @connection.execute('DROP TABLE IF EXISTS sources CASCADE')
    @connection.execute('DROP TABLE IF EXISTS protected_areas CASCADE')
    @connection.execute('DROP TABLE IF EXISTS bk2501011200_sources CASCADE')
    @connection.execute('DROP TABLE IF EXISTS bk2501011201_sources CASCADE')
    @connection.execute('DROP TABLE IF EXISTS bk2501011202_sources CASCADE')
    
    # Clean up any test materialized views
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS bk2501011200_portal_standard_polygons CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS bk2501011201_portal_standard_polygons CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS bk2501011202_portal_standard_polygons CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS bk2501011200_portal_standard_points CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS bk2501011201_portal_standard_points CASCADE')
    @connection.execute('DROP MATERIALIZED VIEW IF EXISTS bk2501011202_portal_standard_points CASCADE')
  end

  test 'initializes cleanup variables correctly' do
    @service.initialize_cleanup_variables
    
    assert_equal @connection, @service.instance_variable_get(:@connection)
    assert_equal ['sources', 'protected_areas'], @service.instance_variable_get(:@tables_to_cleanup)
    assert_nil @service.instance_variable_get(:@original_lock_timeout)
    assert_nil @service.instance_variable_get(:@original_statement_timeout)
    assert_equal({}, @service.instance_variable_get(:@index_cache))
  end

  test 'prepares for cleanup by setting timeouts' do
    @service.initialize_cleanup_variables
    @service.expects(:setup_timeouts).with(30000, 300000)
    @service.prepare_for_cleanup
  end

  test 'performs vacuum operations on existing tables' do
    @service.initialize_cleanup_variables
    
    # Create test tables
    @connection.execute('CREATE TABLE sources (id SERIAL PRIMARY KEY, name VARCHAR)')
    @connection.execute('CREATE TABLE protected_areas (id SERIAL PRIMARY KEY, name VARCHAR)')
    
    # Mock the vacuum operation
    @connection.expects(:execute).with('VACUUM ANALYZE sources')
    @connection.expects(:execute).with('VACUUM ANALYZE protected_areas')
    
    @service.perform_vacuum_operations
  end

  test 'skips vacuum for non-existent tables' do
    @service.initialize_cleanup_variables
    
    # Don't create any tables
    @connection.expects(:execute).never
    
    @service.perform_vacuum_operations
  end

  test 'handles vacuum errors gracefully' do
    @service.initialize_cleanup_variables
    
    # Create test table
    @connection.execute('CREATE TABLE sources (id SERIAL PRIMARY KEY, name VARCHAR)')
    
    # Mock vacuum to raise error
    @connection.expects(:execute).with('VACUUM ANALYZE sources').raises(StandardError, 'Vacuum failed')
    
    # Should not raise error, just log it
    assert_nothing_raised do
      @service.perform_vacuum_operations
    end
  end

  test 'groups backups by timestamp correctly' do
    @service.initialize_cleanup_variables
    
    # Create test backup tables
    @connection.execute('CREATE TABLE bk2501011200_sources (id SERIAL PRIMARY KEY)')
    @connection.execute('CREATE TABLE bk2501011200_protected_areas (id SERIAL PRIMARY KEY)')
    @connection.execute('CREATE TABLE bk2501011201_sources (id SERIAL PRIMARY KEY)')
    @connection.execute('CREATE TABLE bk2501011202_sources (id SERIAL PRIMARY KEY)')
    
    # Mock table listing
    @connection.expects(:tables).returns([
      'bk2501011200_sources', 'bk2501011200_protected_areas', 
      'bk2501011201_sources', 'bk2501011202_sources', 'regular_table'
    ])
    
    result = @service.group_backups_by_timestamp
    
    expected = {
      '2501011200' => ['bk2501011200_sources', 'bk2501011200_protected_areas'],
      '2501011201' => ['bk2501011201_sources'],
      '2501011202' => ['bk2501011202_sources']
    }
    
    assert_equal expected, result
  end

  test 'cleanup_old_backups keeps specified number of backups' do
    @service.initialize_cleanup_variables
    
    # Create test backup tables
    @connection.execute('CREATE TABLE bk2501011200_sources (id SERIAL PRIMARY KEY)')
    @connection.execute('CREATE TABLE bk2501011201_sources (id SERIAL PRIMARY KEY)')
    @connection.execute('CREATE TABLE bk2501011202_sources (id SERIAL PRIMARY KEY)')
    
    # Mock table listing and grouping
    @service.expects(:group_backups_by_timestamp).returns({
      '2501011200' => ['bk2501011200_sources'],
      '2501011201' => ['bk2501011201_sources'],
      '2501011202' => ['bk2501011202_sources']
    })
    
    @service.expects(:sort_tables_by_dependency).with(['bk2501011200_sources']).returns(['bk2501011200_sources'])
    @connection.expects(:drop_table).with('bk2501011200_sources')
    
    # Mock transaction
    @connection.expects(:transaction).yields
    
    result = @service.cleanup_old_backups(2)
    assert_equal 1, result
  end

  test 'cleanup_old_backups keeps all backups when under limit' do
    @service.initialize_cleanup_variables
    
    # Create only one backup
    @connection.execute('CREATE TABLE bk2501011200_sources (id SERIAL PRIMARY KEY)')
    
    @service.expects(:group_backups_by_timestamp).returns({
      '2501011200' => ['bk2501011200_sources']
    })
    
    @connection.expects(:drop_table).never
    
    # Mock transaction
    @connection.expects(:transaction).yields
    
    result = @service.cleanup_old_backups(2)
    assert_equal 0, result
  end

  test 'sort_tables_by_dependency returns tables in correct order' do
    @service.initialize_cleanup_variables
    
    tables = ['bk2501011200_sources', 'bk2501011200_protected_areas']
    
    # Mock the dependency order
    @config.stubs(:junction_tables).returns({ 'junction_table' => 'staging_junction' })
    @config.stubs(:main_entity_tables).returns({ 'protected_areas' => 'staging_protected_areas' })
    @config.stubs(:independent_table_names).returns({ 'sources' => 'staging_sources' })
    
    @service.expects(:extract_table_name_from_backup).with('bk2501011200_sources').returns('sources')
    @service.expects(:extract_table_name_from_backup).with('bk2501011200_protected_areas').returns('protected_areas')
    
    result = @service.sort_tables_by_dependency(tables)
    
    # Should return in dependency order: junction, main entities, independent
    expected = ['bk2501011200_protected_areas', 'bk2501011200_sources']
    assert_equal expected, result
  end

  test 'handles drop table errors with cascade' do
    @service.initialize_cleanup_variables
    
    @service.expects(:group_backups_by_timestamp).returns({
      '2501011200' => ['bk2501011200_sources']
    })
    @service.expects(:sort_tables_by_dependency).returns(['bk2501011200_sources'])
    
    # Mock drop table to raise dependency error first, then succeed with cascade
    @connection.expects(:drop_table).with('bk2501011200_sources').raises(ActiveRecord::StatementInvalid.new('DependentObjectsStillExist'))
    @connection.expects(:drop_table).with('bk2501011200_sources', if_exists: true, force: :cascade)
    
    # Mock transaction
    @connection.expects(:transaction).yields
    
    result = @service.cleanup_old_backups(1)
    assert_equal 1, result
  end

  test 'restore_after_cleanup restores timeouts' do
    @service.initialize_cleanup_variables
    @service.expects(:restore_timeouts)
    @service.restore_after_cleanup
  end

  test 'cleanup_after_swap runs complete workflow' do
    service_instance = mock('service_instance')
    Wdpa::Portal::Services::Core::TableCleanupService.expects(:new).returns(service_instance)
    
    service_instance.expects(:initialize_cleanup_variables)
    service_instance.expects(:prepare_for_cleanup)
    service_instance.expects(:perform_vacuum_operations)
    service_instance.expects(:cleanup_old_backups).with(2)
    service_instance.expects(:restore_after_cleanup)
    
    Wdpa::Portal::Services::Core::TableCleanupService.cleanup_after_swap
  end


  test 'cleanup_after_swap handles errors gracefully' do
    service_instance = mock('service_instance')
    Wdpa::Portal::Services::Core::TableCleanupService.expects(:new).returns(service_instance)
    
    service_instance.expects(:initialize_cleanup_variables)
    service_instance.expects(:prepare_for_cleanup)
    service_instance.expects(:perform_vacuum_operations).raises(StandardError, 'Cleanup failed')
    service_instance.expects(:restore_after_cleanup)
    
    assert_raises(StandardError, 'Cleanup failed') do
      Wdpa::Portal::Services::Core::TableCleanupService.cleanup_after_swap
    end
  end

  # --- MATERIALIZED VIEW CLEANUP TESTS ---

  test 'get_backup_materialized_views_for_timestamp returns correct views' do
    @service.initialize_cleanup_variables
    
    # Create test backup materialized views
    @connection.execute('CREATE MATERIALIZED VIEW bk2501011200_portal_standard_polygons AS SELECT 1 as id')
    @connection.execute('CREATE MATERIALIZED VIEW bk2501011200_portal_standard_points AS SELECT 1 as id')
    @connection.execute('CREATE MATERIALIZED VIEW bk2501011201_portal_standard_polygons AS SELECT 1 as id')
    
    # Mock the pg_matviews query result
    mock_result = [
      { 'matviewname' => 'bk2501011200_portal_standard_polygons' },
      { 'matviewname' => 'bk2501011200_portal_standard_points' },
      { 'matviewname' => 'bk2501011201_portal_standard_polygons' },
      { 'matviewname' => 'regular_materialized_view' }
    ]
    
    @connection.expects(:execute).with(regexp_matches(/SELECT matviewname.*FROM pg_matviews/)).returns(mock_result)
    
    result = @service.get_backup_materialized_views_for_timestamp('2501011200')
    
    expected = ['bk2501011200_portal_standard_polygons', 'bk2501011200_portal_standard_points']
    assert_equal expected.sort, result.sort
  end

  test 'cleanup_old_backups includes materialized views' do
    @service.initialize_cleanup_variables
    
    # Mock table grouping
    @service.expects(:group_backups_by_timestamp).returns({
      '2501011200' => ['bk2501011200_sources'],
      '2501011201' => ['bk2501011201_sources'],
      '2501011202' => ['bk2501011202_sources']
    })
    
    # Mock materialized view lookup for the timestamp to be removed
    @service.expects(:get_backup_materialized_views_for_timestamp).with('2501011200').returns(['bk2501011200_portal_standard_polygons'])
    
    # Mock table cleanup
    @service.expects(:sort_tables_by_dependency).with(['bk2501011200_sources']).returns(['bk2501011200_sources'])
    @connection.expects(:drop_table).with('bk2501011200_sources')
    
    # Mock materialized view cleanup
    @connection.expects(:execute).with('DROP MATERIALIZED VIEW IF EXISTS bk2501011200_portal_standard_polygons CASCADE')
    
    # Mock transaction
    @connection.expects(:transaction).yields
    
    result = @service.cleanup_old_backups(2)
    assert_equal 2, result  # 1 table + 1 materialized view
  end

  test 'cleanup_old_backups handles materialized view drop errors gracefully' do
    @service.initialize_cleanup_variables
    
    # Mock grouping with only materialized views
    @service.expects(:group_backups_by_timestamp).returns({
      '2501011200' => []
    })
    
    @service.expects(:get_backup_materialized_views_for_timestamp).with('2501011200').returns(['bk2501011200_portal_standard_polygons'])
    
    # Mock materialized view drop to raise error
    @connection.expects(:execute).with('DROP MATERIALIZED VIEW IF EXISTS bk2501011200_portal_standard_polygons CASCADE')
      .raises(ActiveRecord::StatementInvalid.new('Drop failed'))
    
    # Mock transaction
    @connection.expects(:transaction).yields
    
    # Should not raise error, just log it and continue
    assert_nothing_raised do
      result = @service.cleanup_old_backups(1)
      assert_equal 0, result  # No successful drops due to error
    end
  end

  test 'cleanup_old_backups keeps all backups when under limit including materialized views' do
    @service.initialize_cleanup_variables
    
    # Mock grouping with only one backup
    @service.expects(:group_backups_by_timestamp).returns({
      '2501011200' => ['bk2501011200_sources']
    })
    
    # Should not call materialized view lookup since we're keeping all backups
    @service.expects(:get_backup_materialized_views_for_timestamp).never
    
    # Should not drop anything
    @connection.expects(:drop_table).never
    @connection.expects(:execute).never
    
    # Mock transaction
    @connection.expects(:transaction).yields
    
    result = @service.cleanup_old_backups(2)
    assert_equal 0, result
  end

  test 'get_backup_materialized_views_for_timestamp finds backup views for live materialized views' do
    @service.initialize_cleanup_variables
    
    # Mock the generate_backup_name method
    Wdpa::Portal::Config::PortalImportConfig.stubs(:generate_backup_name).returns { |view, timestamp| "bk#{timestamp}_#{view}" }
    
    # Mock individual backup view existence checks
    @connection.stubs(:execute).with(/SELECT 1.*matviewname = 'bk2501011200_portal_standard_polygons'/).returns([{ '1' => '1' }])  # Exists
    @connection.stubs(:execute).with(/SELECT 1.*matviewname = 'bk2501011200_portal_standard_points'/).returns([])  # Doesn't exist
    @connection.stubs(:execute).with(/SELECT 1.*matviewname = 'bk2501011200_portal_downloads_protected_areas'/).returns([{ '1' => '1' }])  # Exists
    
    result = @service.get_backup_materialized_views_for_timestamp('2501011200')
    
    # Should only include backup views that actually exist
    expected_backups = ['bk2501011200_portal_standard_polygons', 'bk2501011200_portal_downloads_protected_areas']
    assert_equal expected_backups.sort, result.sort
  end
end
