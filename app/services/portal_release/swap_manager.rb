# frozen_string_literal: true

module PortalRelease
  class SwapManager
    TABLES = %w[
      protected_areas
      protected_area_parcels
      sources
    ].freeze

    def finalise!(label:, log:, notify:)
      # 1) Ensure staging has required indexes/FKs before swap (if we created lightweight)
      begin
        mgr = Wdpa::Portal::Managers::StagingTableManager
        unless mgr.include_indexes?
          mgr.add_all_indexes
          log.event('staging_indexes_applied')
        end
        unless mgr.include_foreign_keys?
          mgr.add_all_foreign_keys
          log.event('staging_foreign_keys_applied')
        end
      rescue StandardError => e
        log.event('staging_post_build_enhancements_failed', payload: { error: e.message })
        Rails.logger.warn("Post-build staging enhancements failed: #{e.class}: #{e.message}")
      end

      # 2) Swap staging -> live unless dry-run
      if ActiveModel::Type::Boolean.new.cast(ENV.fetch('PP_RELEASE_DRY_RUN', nil))
        log.event('swap_skipped', payload: { label: label, reason: 'dry_run' })
        notify.phase('Swap skipped (dry run)')
        return
      end

      begin
        Wdpa::Portal::Services::Core::TableSwapService.promote_staging_to_live
        log.event('swap_completed', payload: { label: label })
        notify.phase('Swap completed — staging promoted to live tables')
      rescue StandardError => e
        log.event('swap_failed', payload: { error: e.message })
        notify.error(e, phase: 'finalise_swap')
        raise
      end
    end

    def rollback_to!(timestamp)
      notifier = ::PortalRelease::Notifier.new('PP_ROLLBACK')

      # Validate that the timestamp exists before attempting rollback
      available_backups = Wdpa::Portal::Services::Core::TableRollbackService.list_available_backups
      unless available_backups.include?(timestamp)
        error_msg = "Rollback timestamp '#{timestamp}' not found. Available timestamps: #{available_backups.join(', ')}"
        Rails.logger.error(error_msg)
        notifier.rollback_failed(StandardError.new(error_msg), timestamp)
        raise ArgumentError, error_msg
      end

      begin
        # 1. Perform the database rollback (CRITICAL - if this fails, rollback fails)
        Rails.logger.info("Starting database rollback to backup #{timestamp}...")
        Wdpa::Portal::Services::Core::TableRollbackService.rollback_to_backup(timestamp)
        Rails.logger.info("Database rollback to backup #{timestamp} completed")

        # Mark rollback as successful since database is restored
        notifier.rollback_ok(timestamp)
      rescue StandardError => e
        Rails.logger.error("Database rollback failed: #{e.class}: #{e.message}")
        notifier.rollback_failed(e, timestamp)
        raise
      end

      # 2. Perform cleanup operations (NON-CRITICAL - if these fail, rollback still succeeded)
      begin
        # Clear generated downloads (S3 + Redis cache)
        Download.clear_downloads
        Rails.logger.info('Downloads cleared successfully')

        # Rebuild search index to reflect rolled-back data
        Search::Index.delete
        Search::Index.create
        Rails.logger.info('Search index rebuilt successfully')

        # Clear Rails cache to ensure fresh data is served
        Rails.cache.clear
        Rails.logger.info('Rails cache cleared successfully')

        Rails.logger.info('Rollback cleanup completed successfully')
        notifier.rollback_cleanup_okay(timestamp)
      rescue StandardError => e
        # Log cleanup failure but don't fail the rollback
        Rails.logger.warn("Rollback cleanup failed (but database rollback succeeded): #{e.class}: #{e.message}")
        notifier.rollback_cleanup_failed(e, timestamp)
      end
    end
  end
end
