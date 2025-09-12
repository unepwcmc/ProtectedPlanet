namespace :portal_importer do
  desc 'Complete portal import workflow to import data from Data Management Portal'
  task import: :environment do
    Wdpa::Portal::Services::Workflows::PortalImportWorkflowService.run_complete_workflow
  end

  desc 'List available backups for rollback'
  task list_backups: :environment do
    Wdpa::Portal::Services::Workflows::PortalRollbackWorkflowService.list_available_backups
  end

  desc 'Rollback to specific backup timestamp'
  task :rollback, [:timestamp] => :environment do |_t, args|
    Wdpa::Portal::Services::Workflows::PortalRollbackWorkflowService.rollback_to_backup(args[:timestamp])
  end

  # NOTICE: This is already included in Wdpa::Portal::Services::Workflows::PortalImportWorkflowService.run_complete_workflow
  # cleanup_after_swap also includes cleanup_old_backups
  desc 'Clean up after swap (vacuum and cleanup old backups)'
  task cleanup_after_swap: :environment do
    Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowService.cleanup_after_swap
  end

  # NOTICE: This is already included in Wdpa::Portal::Services::Workflows::PortalImportWorkflowService.run_complete_workflow
  desc 'Clean up old backup tables (default: keep last Wdpa::Portal::Config::PortalImportConfig.keep_backup_count)'
  task :cleanup_backups, [:keep_count] => :environment do |_t, args|
    keep_count = args[:keep_count] ? args[:keep_count].to_i : Wdpa::Portal::Config::PortalImportConfig.keep_backup_count
    Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowService.cleanup_old_backups(keep_count)
  end
end
