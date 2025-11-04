# frozen_string_literal: true

module PortalRelease
  class Cleanup
    class << self
      def post_swap!(log)
        if ActiveModel::Type::Boolean.new.cast(ENV.fetch('PP_RELEASE_DRY_RUN', nil))
          # Analyze staging tables in dry-run for visibility
          [::Staging::ProtectedArea.table_name, ::Staging::ProtectedAreaParcel.table_name,
            ::Staging::Source.table_name].each do |t|
            ActiveRecord::Base.connection.execute("ANALYZE #{t}")
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
            Rails.cache.clear

            log.event('post_swap_cleanup_done')
          rescue StandardError => e
            Rails.logger.warn("Post-swap cleanup failed: #{e.class}: #{e.message}")
            log.event('post_swap_cleanup_failed', payload: { error: e.message })
          end
        end
      end

      def retention!(log, keep_prev: 1)
        # Backups are cleaned in cleanup_after_swap; keep method for compatibility/logging
        log.event('retention_done', payload: { keep_prev: keep_prev })
      end
    end
  end
end
