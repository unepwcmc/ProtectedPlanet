# frozen_string_literal: true

module PortalRelease
  class Cleanup
    class << self
      def post_swap!(log, notifier: nil)
        if ActiveModel::Type::Boolean.new.cast(ENV.fetch('PP_RELEASE_DRY_RUN', nil))
          # Analyze staging tables in dry-run for visibility
          [::Staging::ProtectedArea.table_name, ::Staging::ProtectedAreaParcel.table_name,
            ::Staging::Source.table_name].each do |t|
            ActiveRecord::Base.lease_connection.execute("ANALYZE #{t}")
          end
          log.event('post_swap_done_dry_run')
        else
          # Delegate to core cleanup: VACUUM ANALYZE live tables and clean old backups
          begin
            Wdpa::Portal::Services::Core::TableCleanupService.cleanup_after_swap

            # Rebuild searchable index to reflect new release data
            Search::Index.delete
            Search::Index.create

            # Invalidate previously generated downloads so new requests regenerate against the new release
            # This also cleans up the temporary download views created by the generators. clean_tmp_download_views
            Download.clear_downloads

            # Clear Rails cache to ensure fresh data is served
            clear_cache_preserving_sitemap_fallback

            warm_sitemap(log)

            log.event('post_swap_cleanup_done')
          rescue StandardError => e
            Rails.logger.warn("Post-swap cleanup failed: #{e.class}: #{e.message}")
            log.event('post_swap_cleanup_failed', payload: { error: e.message })
            notifier&.error(e, phase: 'post_swap_cleanup')
          end
        end
      end

      def retention!(log, keep_prev: 1)
        # Backups are cleaned in cleanup_after_swap; keep method for compatibility/logging
        log.event('retention_done', payload: { keep_prev: keep_prev })
      end

      private

      # Losing the sitemap's last-good bounds to the clear turns a slow post-swap
      # bounds query into a 500 on every sitemap URL. See Sitemap.
      def clear_cache_preserving_sitemap_fallback
        Sitemap.preserving_last_good_bounds { Rails.cache.clear }
      rescue StandardError => e
        # The clear itself must still happen; the rest of the release depends on it.
        Rails.logger.warn("Sitemap fallback preservation failed: #{e.class}: #{e.message}")
        Rails.cache.clear
      end

      # Spend the bounds query here, in the job container, rather than on the first
      # crawler's Puma thread. Never fatal: the cleanup above has already succeeded.
      def warm_sitemap(log)
        chunks = Sitemap.warm!(sitemap_base_url)
        log.event('sitemap_warmed', payload: { protected_area_chunks: chunks })
      rescue StandardError => e
        Rails.logger.warn("Sitemap warm after swap failed: #{e.class}: #{e.message}")
        log.event('sitemap_warm_failed', payload: { error: e.message })
      end

      # No request to take a host from. nil still warms the expensive half.
      def sitemap_base_url
        host = AppSecrets.host.presence
        host && "https://#{host}"
      end
    end
  end
end
