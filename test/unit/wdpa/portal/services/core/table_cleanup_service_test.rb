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
    Wdpa::Portal::Config::PortalImportConfig.stubs(:portal_live_materialised_view_values).returns(@config.portal_live_materialised_view_values)
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

  test 'restore_after_cleanup restores timeouts' do
    @service.initialize_cleanup_variables
    @service.expects(:restore_timeouts)
    @service.restore_after_cleanup
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

  # --- backup grouping / dependency ordering / retention (PG-migration-fragile logic) ---
  CFG = Wdpa::Portal::Config::PortalImportConfig

  test 'group_backups_by_timestamp buckets backup tables by timestamp and skips non-backup tables' do
    conn = mock('conn')
    conn.stubs(:tables).returns(%w[live_table bk2501011200_sources bk2501011200_protected_areas bk2501011201_sources])
    @service.instance_variable_set(:@connection, conn)
    CFG.stubs(:is_backup_table?).with('live_table').returns(false)
    %w[bk2501011200_sources bk2501011200_protected_areas bk2501011201_sources].each { |t| CFG.stubs(:is_backup_table?).with(t).returns(true) }
    CFG.stubs(:extract_backup_timestamp).with('bk2501011200_sources').returns('2501011200')
    CFG.stubs(:extract_backup_timestamp).with('bk2501011200_protected_areas').returns('2501011200')
    CFG.stubs(:extract_backup_timestamp).with('bk2501011201_sources').returns('2501011201')

    groups = @service.send(:group_backups_by_timestamp)
    assert_equal %w[bk2501011200_sources bk2501011200_protected_areas], groups['2501011200']
    assert_equal %w[bk2501011201_sources], groups['2501011201']
    refute groups.key?(nil), 'non-backup table must be excluded'
  end

  test 'sort_tables_by_dependency orders backups junction -> main -> independent' do
    CFG.stubs(:junction_tables).returns({ 'countries_pas' => {} })
    CFG.stubs(:main_entity_tables).returns({ 'protected_areas' => {} })
    CFG.stubs(:independent_table_names).returns({ 'sources' => {} })
    { 'bk1_countries_pas' => 'countries_pas', 'bk1_protected_areas' => 'protected_areas', 'bk1_sources' => 'sources' }
      .each { |bk, orig| CFG.stubs(:extract_table_name_from_backup).with(bk).returns(orig) }

    result = @service.send(:sort_tables_by_dependency, %w[bk1_sources bk1_protected_areas bk1_countries_pas])
    assert_equal %w[bk1_countries_pas bk1_protected_areas bk1_sources], result
  end

  test 'sort_materialized_views_by_dependency follows the config deletion sequence' do
    CFG.stubs(:deletion_sequence_materialized_view_names).returns(%w[polygons points])
    CFG.stubs(:extract_table_name_from_backup).with('bk1_polygons').returns('polygons')
    CFG.stubs(:extract_table_name_from_backup).with('bk1_points').returns('points')
    result = @service.send(:sort_materialized_views_by_dependency, %w[bk1_points bk1_polygons])
    assert_equal %w[bk1_polygons bk1_points], result
  end

  # Plain object so #transaction actually yields AND returns the block value (mocha's
  # .yields returns the stub value, not the block result, which cleanup_old_backups needs).
  def yielding_connection
    conn = Object.new
    def conn.transaction; yield; end
    conn
  end

  test 'cleanup_old_backups keeps everything (returns 0) when within the limit' do
    @service.instance_variable_set(:@connection, yielding_connection)
    @service.stubs(:group_backups_by_timestamp).returns({ '2501011201' => ['t1'], '2501011202' => ['t2'] })
    assert_equal 0, @service.send(:cleanup_old_backups, 2)
  end

  test 'cleanup_old_backups deletes the oldest timestamps beyond keep_count and sums the cleaned objects' do
    @service.instance_variable_set(:@connection, yielding_connection)
    @service.stubs(:group_backups_by_timestamp).returns({
      '2501011200' => ['bkold'], '2501011201' => ['bkmid'], '2501011202' => ['bknew']
    })
    # keep 1 -> newest 2501011202 kept; 2501011201 + 2501011200 removed
    @service.expects(:cleanup_backup_tables_for_timestamp).with('2501011201', ['bkmid']).returns(1)
    @service.expects(:cleanup_backup_tables_for_timestamp).with('2501011200', ['bkold']).returns(1)
    @service.stubs(:cleanup_backup_download_view_for_timestamp).returns(0)
    @service.stubs(:cleanup_backup_materialized_views_for_timestamp).returns(0)

    assert_equal 2, @service.send(:cleanup_old_backups, 1)
  end

end
