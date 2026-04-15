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

end
