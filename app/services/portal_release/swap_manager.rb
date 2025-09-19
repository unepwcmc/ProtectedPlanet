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
      if ActiveModel::Type::Boolean.new.cast(ENV['PP_RELEASE_DRY_RUN'])
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

    def rollback!
      timestamp = ENV['PP_RELEASE_ROLLBACK_TO']
      unless timestamp && !timestamp.strip.empty?
        Rails.logger.warn('Rollback requested but PP_RELEASE_ROLLBACK_TO not set (YYMMDDHHMM). Use rake pp:portal:rollback with env or set variable.')
        return
      end

      notifier = ::PortalRelease::Notifier.new('PP_ROLLBACK')
      begin
        Wdpa::Portal::Services::Core::TableRollbackService.rollback_to_backup(timestamp)
        Rails.logger.info("Rollback to backup #{timestamp} completed")
        notifier.rollback_ok(timestamp)
      rescue StandardError => e
        Rails.logger.error("Rollback failed: #{e.class}: #{e.message}")
        notifier.rollback_failed(e, timestamp)
        raise
      end
    end
  end
end

