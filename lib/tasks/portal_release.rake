namespace :pp do
  namespace :portal do
    desc "Run portal-backed WDPA release. Usage: rake pp:portal:release['WDPA_YYYY_MM']"
    task :release, [:label] => :environment do |_t, args|
      # Default to e.g. "Mar2025" when no label is supplied
      # Each month we run release for next month data so month +1 is used to get the correct label
      label = args[:label] || Time.now.utc.advance(months: 1).strftime('%b%Y')
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

      begin
        # Use the existing TableCleanupService
        service = Wdpa::Portal::Services::Core::TableCleanupService.new
        service.instance_variable_set(:@connection, ActiveRecord::Base.connection)
        service.instance_variable_set(:@index_cache, {})
        service.cleanup_old_backups(keep_count)
        Rails.logger.info '✅ Backup cleanup completed successfully'
      rescue StandardError => e
        Rails.logger.error "❌ Backup cleanup failed: #{e.class}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        exit 1
      end
    end
  end
end
