require 'test_helper'

class Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowServiceTest < ActiveSupport::TestCase
  def setup
    @service = Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowService.new
  end

  test 'cleanup_after_swap calls TableCleanupService' do
    Wdpa::Portal::Services::Core::TableCleanupService.expects(:cleanup_after_swap)

    Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowService.cleanup_after_swap
  end

  test 'cleanup_after_swap handles errors' do
    Wdpa::Portal::Services::Core::TableCleanupService.expects(:cleanup_after_swap).raises(StandardError,
      'Cleanup failed')

    assert_raises(StandardError, 'Cleanup failed') do
      Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowService.cleanup_after_swap
    end
  end

  test 'cleanup_old_backups calls TableCleanupService with keep count' do
    Wdpa::Portal::Services::Core::TableCleanupService.expects(:cleanup_old_backups).with(3).returns(5)

    result = Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowService.cleanup_old_backups(3)
    assert_equal 5, result
  end

  test 'cleanup_old_backups handles errors' do
    Wdpa::Portal::Services::Core::TableCleanupService.expects(:cleanup_old_backups).with(3).raises(StandardError,
      'Cleanup failed')

    assert_raises(StandardError, 'Cleanup failed') do
      Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowService.cleanup_old_backups(3)
    end
  end

  test 'cleanup_old_backups returns cleaned count' do
    Wdpa::Portal::Services::Core::TableCleanupService.expects(:cleanup_old_backups).with(2).returns(10)

    result = Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowService.cleanup_old_backups(2)
    assert_equal 10, result
  end

  test 'cleanup_old_backups with zero keep count' do
    Wdpa::Portal::Services::Core::TableCleanupService.expects(:cleanup_old_backups).with(0).returns(15)

    result = Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowService.cleanup_old_backups(0)
    assert_equal 15, result
  end

  test 'cleanup_old_backups with large keep count' do
    Wdpa::Portal::Services::Core::TableCleanupService.expects(:cleanup_old_backups).with(100).returns(0)

    result = Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowService.cleanup_old_backups(100)
    assert_equal 0, result
  end
end
