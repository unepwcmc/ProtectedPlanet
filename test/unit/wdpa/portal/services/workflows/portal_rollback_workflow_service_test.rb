require 'test_helper'

class Wdpa::Portal::Services::Workflows::PortalRollbackWorkflowServiceTest < ActiveSupport::TestCase
  def setup
    @service = Wdpa::Portal::Services::Workflows::PortalRollbackWorkflowService.new
    @timestamp = '2501011200'
  end

  test 'rollback_to_backup delegates to instance method' do
    service_instance = mock('service_instance')
    Wdpa::Portal::Services::Workflows::PortalRollbackWorkflowService.expects(:new).returns(service_instance)
    service_instance.expects(:rollback_to_backup).with(@timestamp)

    Wdpa::Portal::Services::Workflows::PortalRollbackWorkflowService.rollback_to_backup(@timestamp)
  end

  test 'list_available_backups delegates to instance method' do
    service_instance = mock('service_instance')
    Wdpa::Portal::Services::Workflows::PortalRollbackWorkflowService.expects(:new).returns(service_instance)
    service_instance.expects(:list_available_backups).returns(%w[2501011200 2501011201])

    result = Wdpa::Portal::Services::Workflows::PortalRollbackWorkflowService.list_available_backups
    assert_equal %w[2501011200 2501011201], result
  end

  test 'rollback_to_backup validates timestamp and calls TableRollbackService' do
    @service.expects(:validate_timestamp).with(@timestamp)
    Wdpa::Portal::Services::Core::TableRollbackService.expects(:rollback_to_backup).with(@timestamp)

    @service.rollback_to_backup(@timestamp)
  end

  test 'rollback_to_backup handles errors' do
    @service.expects(:validate_timestamp).with(@timestamp)
    Wdpa::Portal::Services::Core::TableRollbackService.expects(:rollback_to_backup).with(@timestamp).raises(
      StandardError, 'Rollback failed'
    )

    assert_raises(StandardError, 'Rollback failed') do
      @service.rollback_to_backup(@timestamp)
    end
  end

  test 'list_available_backups calls TableRollbackService' do
    Wdpa::Portal::Services::Core::TableRollbackService.expects(:list_available_backups).returns(%w[2501011200
      2501011201])

    result = @service.list_available_backups
    assert_equal %w[2501011200 2501011201], result
  end

  test 'list_available_backups handles errors' do
    Wdpa::Portal::Services::Core::TableRollbackService.expects(:list_available_backups).raises(StandardError,
      'List failed')

    assert_raises(StandardError, 'List failed') do
      @service.list_available_backups
    end
  end

  test 'validate_timestamp passes with valid timestamp' do
    assert_nothing_raised do
      @service.send(:validate_timestamp, @timestamp)
    end
  end

  test 'validate_timestamp exits with nil timestamp' do
    @service.expects(:exit).with(1)

    @service.send(:validate_timestamp, nil)
  end

  test 'validate_timestamp exits with empty timestamp' do
    @service.expects(:exit).with(1)

    @service.send(:validate_timestamp, '')
  end

  test 'validate_timestamp exits with blank timestamp' do
    @service.expects(:exit).with(1)

    @service.send(:validate_timestamp, '   ')
  end

  test 'validate_timestamp with valid timestamp does not exit' do
    @service.expects(:exit).never

    @service.send(:validate_timestamp, @timestamp)
  end

  test 'validate_timestamp with valid timestamp does not print error messages' do
    @service.expects(:puts).never

    @service.send(:validate_timestamp, @timestamp)
  end

  test 'validate_timestamp with invalid timestamp prints error messages' do
    @service.expects(:puts).with('❌ Please provide a backup timestamp')
    @service.expects(:puts).with('Usage: rake portal_importer:rollback[20250110_143022]')
    @service.expects(:puts).with('Run "rake portal_importer:list_backups" to see available timestamps')
    @service.expects(:exit).with(1)

    @service.send(:validate_timestamp, nil)
  end
end
