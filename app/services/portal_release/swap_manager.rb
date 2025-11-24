# frozen_string_literal: true

module PortalRelease
  class SwapManager
    TABLES = %w[
      protected_areas
      protected_area_parcels
      sources
    ].freeze

    def finalise!(release:, log:, notify:)
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
        log.event('swap_skipped', payload: { label: release.label, reason: 'dry_run' })
        notify.phase('Swap skipped (dry run)')
        return
      end

      begin
        # Capture the previously current release before we swap
        previous_current_release = Release.current_release

        backup_timestamp = Wdpa::Portal::Services::Core::TableSwapService.promote_staging_to_live
        log.event('swap_completed', payload: { label: release.label, backup_timestamp: backup_timestamp })

        # 3) Atomically record backup on previous and make new release current
        parsed_backup_time = Release.parse_backup_timestamp_string(backup_timestamp)
        Release.transaction do
          if previous_current_release && parsed_backup_time
            previous_current_release.update!(backup_timestamp: parsed_backup_time)
          end
          release.make_current!
        end

        # Emit events after state changes succeed
        if previous_current_release && parsed_backup_time
          log.event('previous_release_backup_recorded',
            payload: { label: previous_current_release.label, backup_timestamp: backup_timestamp })
        end
        log.event('release_made_current', payload: { label: release.label })
      rescue StandardError => e
        log.event('swap_failed', payload: { error: e.message })
        notify.error(e, phase: 'finalise_swap')
        raise
      end
    end

    def rollback_to!(timestamp)
      notifier = ::PortalRelease::Notifier.new('PP_ROLLBACK')
      # Announce rollback start
      notifier.rollback_started(timestamp)

      # Check if a release is currently running (CRITICAL SAFETY CHECK)
      unless PortalRelease::Lock.lock_available?
        error_msg = 'Cannot rollback while a release is in progress. Please wait for the current release to complete or abort it first.'
        Rails.logger.error(error_msg)
        notifier.rollback_failed(StandardError.new(error_msg), timestamp)
        raise StandardError, error_msg
      end

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
        Wdpa::Portal::Services::Core::TableRollbackService.rollback_to_backup(timestamp, notifier: notifier)
        Rails.logger.info("Database rollback to backup #{timestamp} completed")

        # 2. Find and make the corresponding release current
        target_release = Release.find_by_backup_timestamp_string(timestamp)
        if target_release
          target_release.make_current!
          Rails.logger.info("Made release #{target_release.label} current after rollback")
        else
          Rails.logger.warn("No release found with backup_timestamp matching #{timestamp}")
        end

        # Mark rollback as successful since database is restored
        notifier.rollback_ok(timestamp)
      rescue StandardError => e
        Rails.logger.error("Database rollback failed: #{e.class}: #{e.message}")
        notifier.rollback_failed(e, timestamp)
        raise
      end

      # 3. Post-swap cleanup (NON-CRITICAL). Always use Cleanup.post_swap! with a logger
      begin
        notifier.rollback_step_started('post_swap_cleanup', timestamp)
        log = if target_release
          ::PortalRelease::Logger.new(target_release)
        else
          # Lightweight shim to satisfy interface when no release record is available
          Class.new do
            def event(event_name, payload: {}, phase: nil)
              json = { event: event_name.to_s, phase: phase&.to_s, payload: payload }.to_json
              Rails.logger.info(json)
            end
          end.new
        end

        Cleanup.post_swap!(log, notifier: notifier)
        Rails.logger.info('Rollback post-swap cleanup completed via Cleanup.post_swap!')
        notifier.phase("Post-swap cleanup completed (backup #{timestamp})")
        notifier.rollback_cleanup_okay(timestamp)
      rescue StandardError => e
        Rails.logger.warn("Rollback cleanup failed (but database rollback succeeded): #{e.class}: #{e.message}")
        notifier.rollback_cleanup_failed(e, timestamp)
      end
    end
  end
end
