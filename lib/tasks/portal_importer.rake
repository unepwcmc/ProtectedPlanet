namespace :portal_importer do
  desc 'Complete portal import workflow to import data from Data Management Portal'
  task import: :environment do
    Wdpa::Portal::Services::Workflows::PortalImportWorkflowService.run_complete_workflow
  end

  desc 'Rollback to specific backup timestamp'
  task :rollback, [:timestamp] => :environment do |_t, args|
    Wdpa::Portal::Services::Workflows::PortalRollbackWorkflowService.rollback_to_backup(args[:timestamp])
  end

  desc 'List available backups for rollback'
  task list_backups: :environment do
    Wdpa::Portal::Services::Workflows::PortalRollbackWorkflowService.list_available_backups
  end

  desc 'Clean up old backup tables (default: keep last 3)'
  task :cleanup_backups, [:keep_count] => :environment do |_t, args|
    keep_count = (args[:keep_count] || 3).to_i
    Wdpa::Portal::Services::Workflows::PortalCleanupWorkflowService.cleanup_old_backups(keep_count)
  end

  desc 'Compare live vs staging table structures'
  task compare_structures: :environment do
    success = Wdpa::Portal::Services::Workflows::PortalStructureComparisonWorkflowService.compare_structures
    exit(success ? 0 : 1)
  end
end
