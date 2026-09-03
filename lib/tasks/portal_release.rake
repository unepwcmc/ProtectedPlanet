namespace :pp do
  namespace :portal do
    desc "Run portal-backed WDPA release. Usage: rake pp:portal:release['Nov2025']"
    task :release, [:label] => :environment do |_t, args|
      unless args[:label] && !args[:label].strip.empty?
        Rails.logger.error 'Error: Release label is required. Usage: rake pp:portal:release["Nov2025"]'
        Rails.logger.error 'Label format: MMMYYYY (e.g., Nov2025, Jan2026)'
        exit 1
      end

      label = args[:label].strip
      PortalRelease::Service.new(label: label).run!
    end

    desc 'Abort current in-flight release (drops staging tables)'
    task abort: :environment do
      PortalRelease::Service.abort_current!
    end

    desc 'List available backup timestamps for rollback'
    task list_backups: :environment do
      backups = Wdpa::Portal::Services::Core::TableRollbackService.list_available_backups
      if backups.empty?
        Rails.logger.warn '⚠️ No backup timestamps found.'
      else
        backups
      end
    rescue StandardError => e
      Rails.logger.warn "Error listing backups: #{e.message}"
      exit 1
    end

    desc 'Rollback to specific backup timestamp. Usage: rake pp:portal:rollback[YYMMDDHHMM]'
    task :rollback, [:timestamp] => :environment do |_t, args|
      unless args[:timestamp] && !args[:timestamp].strip.empty?
        Rails.logger.warn 'Error: Timestamp required. Usage: rake pp:portal:rollback[YYMMDDHHMM]'
        exit 1
      end

      PortalRelease::Service.rollback_to!(args[:timestamp])
    end

    desc 'Exit non-zero while a release is running. Used by .kamal/hooks/pre-deploy to block deploys'
    task deploy_gate: :environment do
      # lock_available? answers by taking the lock and releasing it again. That is
      # safe here: this task runs in its own container, so its own Postgres
      # session, and from a different session pg_try_advisory_lock simply fails
      # while a release holds the lock. Do NOT reuse this check from a process
      # that might itself hold the lock — advisory locks are re-entrant, so it
      # would take the count 1 -> 2, release 2 -> 1, and report "available".
      unless PortalRelease::Lock.lock_available?
        release = Release.order(created_at: :desc).first
        warn "A portal release is currently running#{release ? " (#{release.label}, state '#{release.state}')" : ''}."
        exit 1
      end

      puts 'No release running.'
    end

    desc 'Show release status summary'
    task status: :environment do
      puts PortalRelease::Service.status_report
    end

    desc 'Manually clean up old backups. Usage: rake pp:portal:cleanup_backups[2] (keeps 2 most recent backups)'
    task :cleanup_backups, [:keep_count] => :environment do |_t, args|
      keep_count = (args[:keep_count] || '1').to_i

      if keep_count < 0
        Rails.logger.error 'Error: keep_count must be >= 0'
        exit 1
      end

      Rails.logger.info "🧹 Starting manual backup cleanup (keeping #{keep_count} most recent backup(s))..."

      notifier = SlackNotifier.new('pp:portal:cleanup_backups')
      notifier.phase("Manually triggered: cleaning up old backups (keeping #{keep_count} most recent)")

      begin
        # Use the existing TableCleanupService
        service = Wdpa::Portal::Services::Core::TableCleanupService.new
        service.instance_variable_set(:@connection, ActiveRecord::Base.lease_connection)
        service.instance_variable_set(:@index_cache, {})
        service.cleanup_old_backups(keep_count)
        Rails.logger.info '✅ Backup cleanup completed successfully'
        notifier.phase_complete('Backup cleanup complete')
      rescue StandardError => e
        Rails.logger.error "❌ Backup cleanup failed: #{e.class}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        notifier.error(e, phase: 'cleanup_backups')
        exit 1
      end
    end
  end
end
