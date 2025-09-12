require 'test_helper'

class Wdpa::Portal::Services::Workflows::PortalImportWorkflowServiceTest < ActiveSupport::TestCase
  def setup
    @service = Wdpa::Portal::Services::Workflows::PortalImportWorkflowService.new
  end

  test 'run_complete_workflow delegates to instance method' do
    service_instance = mock('service_instance')
    Wdpa::Portal::Services::Workflows::PortalImportWorkflowService.expects(:new).returns(service_instance)
    service_instance.expects(:run_complete_workflow).returns(true)

    result = Wdpa::Portal::Services::Workflows::PortalImportWorkflowService.run_complete_workflow
    assert result
  end

  test 'run_complete_workflow executes all steps successfully' do
    # Mock all the workflow steps
    @service.expects(:create_staging_tables).returns(true)
    @service.expects(:import_data_to_staging).returns(true)
    @service.expects(:promote_staging_to_live).returns(true)
    @service.expects(:cleanup_after_workflow).returns(true)

    result = @service.run_complete_workflow
    assert result
  end

  test 'run_complete_workflow stops on staging table creation failure' do
    @service.expects(:create_staging_tables).returns(false)
    @service.expects(:import_data_to_staging).never
    @service.expects(:promote_staging_to_live).never
    @service.expects(:cleanup_after_workflow).never

    result = @service.run_complete_workflow
    refute result
  end

  test 'run_complete_workflow stops on import data failure' do
    @service.expects(:create_staging_tables).returns(true)
    @service.expects(:import_data_to_staging).returns(false)
    @service.expects(:promote_staging_to_live).never
    @service.expects(:cleanup_after_workflow).never

    result = @service.run_complete_workflow
    refute result
  end

  test 'run_complete_workflow stops on promote staging failure' do
    @service.expects(:create_staging_tables).returns(true)
    @service.expects(:import_data_to_staging).returns(true)
    @service.expects(:promote_staging_to_live).returns(false)
    @service.expects(:cleanup_after_workflow).never

    result = @service.run_complete_workflow
    refute result
  end

  test 'run_complete_workflow continues on cleanup failure' do
    @service.expects(:create_staging_tables).returns(true)
    @service.expects(:import_data_to_staging).returns(true)
    @service.expects(:promote_staging_to_live).returns(true)
    @service.expects(:cleanup_after_workflow).returns(false)

    result = @service.run_complete_workflow
    refute result
  end

  test 'run_complete_workflow handles exceptions gracefully' do
    @service.expects(:create_staging_tables).raises(StandardError, 'Test error')
    @service.expects(:import_data_to_staging).never
    @service.expects(:promote_staging_to_live).never
    @service.expects(:cleanup_after_workflow).never

    result = @service.run_complete_workflow
    refute result
  end

  test 'create_staging_tables calls StagingTableManager' do
    Wdpa::Portal::Managers::StagingTableManager.expects(:create_staging_tables)

    result = @service.send(:create_staging_tables)
    assert result
  end

  test 'create_staging_tables handles errors' do
    Wdpa::Portal::Managers::StagingTableManager.expects(:create_staging_tables).raises(StandardError, 'Creation failed')

    result = @service.send(:create_staging_tables)
    refute result
  end

  test 'import_data_to_staging calls Portal::Importer' do
    import_results = { sources: { success: true, hard_errors: [] } }
    Wdpa::Portal::Importer.expects(:import).with(refresh_materialized_views: true).returns(import_results)
    @service.expects(:check_for_import_errors).returns(true)

    result = @service.send(:import_data_to_staging)
    assert result
  end

  test 'import_data_to_staging handles import errors' do
    import_results = { sources: { success: true, hard_errors: ['Error 1', 'Error 2'] } }
    Wdpa::Portal::Importer.expects(:import).with(refresh_materialized_views: true).returns(import_results)
    @service.expects(:check_for_import_errors).returns(false)

    result = @service.send(:import_data_to_staging)
    refute result
  end

  test 'import_data_to_staging handles exceptions' do
    Wdpa::Portal::Importer.expects(:import).with(refresh_materialized_views: true).raises(StandardError,
      'Import failed')

    result = @service.send(:import_data_to_staging)
    refute result
  end

  test 'promote_staging_to_live calls TableSwapService' do
    Wdpa::Portal::Services::Core::TableSwapService.expects(:promote_staging_to_live)

    result = @service.send(:promote_staging_to_live)
    assert result
  end

  test 'promote_staging_to_live handles errors' do
    Wdpa::Portal::Services::Core::TableSwapService.expects(:promote_staging_to_live).raises(StandardError,
      'Swap failed')

    result = @service.send(:promote_staging_to_live)
    refute result
  end

  test 'cleanup_after_workflow calls PortalCleanupWorkflowService' do
    Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowService.expects(:cleanup_after_swap)

    result = @service.send(:cleanup_after_workflow)
    assert result
  end

  test 'cleanup_after_workflow handles errors gracefully' do
    Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowService.expects(:cleanup_after_swap).raises(StandardError,
      'Cleanup failed')

    result = @service.send(:cleanup_after_workflow)
    refute result
  end

  test 'check_for_import_errors returns true when no hard errors' do
    @service.instance_variable_set(:@results, { sources: { success: true, hard_errors: [] } })

    result = @service.send(:check_for_import_errors)
    assert result
  end

  test 'check_for_import_errors returns true when results is not a hash' do
    @service.instance_variable_set(:@results, 'not a hash')

    result = @service.send(:check_for_import_errors)
    assert result
  end

  test 'check_for_import_errors returns true when no hard_errors key' do
    @service.instance_variable_set(:@results, { sources: { success: true } })

    result = @service.send(:check_for_import_errors)
    assert result
  end

  test 'check_for_import_errors returns false when hard errors exist' do
    @service.instance_variable_set(:@results, { sources: { success: true, hard_errors: ['Error 1', 'Error 2'] } })

    result = @service.send(:check_for_import_errors)
    refute result
  end

  test 'refresh_materialized_views calls ViewManager' do
    Wdpa::Portal::Managers::ViewManager.expects(:refresh_materialized_views)

    @service.send(:refresh_materialized_views)
  end

  test 'refresh_materialized_views handles errors' do
    Wdpa::Portal::Managers::ViewManager.expects(:refresh_materialized_views).raises(StandardError, 'Refresh failed')

    assert_raises(StandardError, 'Refresh failed') do
      @service.send(:refresh_materialized_views)
    end
  end
end
