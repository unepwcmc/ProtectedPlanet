# frozen_string_literal: true

module PortalRelease
  class Preflight
    class << self
      def create_staging_mvs!(log)
        # Default to true if PP_RELEASE_CREATE_STAGING_MATERIALIZED_VIEWS is not set
        create_staging_materialized_views = ENV.fetch('PP_RELEASE_CREATE_STAGING_MATERIALIZED_VIEWS', nil)
        return unless ActiveModel::Type::Boolean.new.cast(create_staging_materialized_views.nil? ? 'true' : create_staging_materialized_views)

        # Create and refresh staging MVs (this creates them and populates with data)
        Wdpa::Portal::Managers::ViewManager.ensure_staging_materialized_views!
        log.event('staging_mvs_created')
      end

      def run!(release, log, notify, _ctx)
        contract!
        counts = counts_snapshot
        # Require at least one of points/polygons to be present; allow one to be zero
        if counts[:points].zero? && counts[:polygons].zero?
          raise 'Empty source views (both points and polygons are empty)'
        end

        # Optionally ensure sources present; comment this out if not required
        # raise 'Empty sources view' if counts[:sources].zero?
        check_geometry!
        check_duplicates!

        release.update!(state: 'preflight_ok', stats_json: { source_counts: counts })
        log.event('preflight_ok', payload: counts)
        notify.phase('Preflight OK — source views and geometry checks passed', counts: counts)
      end

      def contract!
        # Will raise if not found
        Wdpa::Portal::Managers::ViewManager.validate_required_views_exist || raise('Required portal views missing')
      end

      def counts_snapshot
        conn = ActiveRecord::Base.connection

        views = Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views
        {
          points: conn.select_value("SELECT COUNT(*) FROM #{views[:points]}").to_i,
          polygons: conn.select_value("SELECT COUNT(*) FROM #{views[:polygons]}").to_i,
          sources: conn.select_value("SELECT COUNT(*) FROM #{views[:sources]}").to_i
        }
      end

      def check_geometry!
        conn = ActiveRecord::Base.connection

        views = Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views
        bad_points = conn.select_value("SELECT COUNT(*) FROM #{views[:points]}   WHERE wkb_geometry IS NOT NULL AND (ST_SRID(wkb_geometry) <> 4326 OR NOT ST_IsValid(wkb_geometry))").to_i
        bad_polys  = conn.select_value("SELECT COUNT(*) FROM #{views[:polygons]} WHERE wkb_geometry IS NOT NULL AND (ST_SRID(wkb_geometry) <> 4326 OR NOT ST_IsValid(wkb_geometry))").to_i
        return unless bad_points.positive? || bad_polys.positive?

        raise "Invalid geometry in views: points=#{bad_points}, polygons=#{bad_polys}"
      end

      def check_duplicates!
        conn = ActiveRecord::Base.connection

        views = Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views
        dup_points = conn.select_value(<<~SQL).to_i
          SELECT COUNT(*) FROM (
            SELECT site_id, site_pid, COUNT(*) c
            FROM #{views[:points]}
            GROUP BY 1,2
            HAVING COUNT(*) > 1
          ) d
        SQL
        dup_polys = conn.select_value(<<~SQL).to_i
          SELECT COUNT(*) FROM (
            SELECT site_id, site_pid, COUNT(*) c
            FROM #{views[:polygons]}
            GROUP BY 1,2
            HAVING COUNT(*) > 1
          ) d
        SQL
        return unless dup_points.positive? || dup_polys.positive?

        raise "Duplicate rows by (site_id, site_pid): points=#{dup_points}, polygons=#{dup_polys}"
      end


      # Creates or replaces the staging portal downloads view used by generators/exporters
      # Combines polygons and points from staging materialized views.
      def create_portal_downloads_view!(log = nil)
        conn = ActiveRecord::Base.connection
        downloads_view = Wdpa::Portal::Config::PortalImportConfig::PORTAL_DOWNALOAD_VIEWS
        staging_view = Wdpa::Portal::Config::PortalImportConfig.generate_staging_name(downloads_view)
        backup_timestamp = ::Release.current_backup_timestamp_string
        backup_view = Wdpa::Portal::Config::PortalImportConfig.generate_backup_name(downloads_view, backup_timestamp)

        # Validate that required materialized views exist before building query
        validate_required_materialized_views_for_downloads!

        # Atomic staging download view creation and rename swap (all in transaction - must all succeed or all fail)
        conn.transaction do
          # Step 1: Drop staging view if exists, then create fresh (inside transaction for atomicity)
          # Note: ActiveRecord doesn't have drop_view, so we use SQL directly
          as_query = Download::Queries.build_query_for_downloads_view('portal')
          conn.execute("DROP VIEW IF EXISTS #{staging_view} CASCADE")
          conn.execute("CREATE VIEW #{staging_view} AS (SELECT #{as_query[:select]} FROM #{as_query[:from]})")

          # Step 2: Check if live view exists before renaming
          if conn.data_source_exists?(downloads_view)
            # Rename live view → backup (timestamped name like bk2501011200_portal_downloads_protected_areas)
            # Active queries will continue to work on the renamed view
            conn.execute("ALTER VIEW #{downloads_view} RENAME TO #{backup_view}")
          end

          # Step 3: Rename staging view → live view
          # New queries will use the new view
          # If any step fails, transaction rolls back and all changes are undone
          conn.execute("ALTER VIEW #{staging_view} RENAME TO #{downloads_view}")
        end

        # Note: Backup views (bk#{timestamp}_#{view_name}) are cleaned up by TableCleanupService
        # during the cleanup_after_swap process, along with other backup tables and materialized views

        log&.event('portal_downloads_view_created', payload: { view: downloads_view, backup_view: backup_view })
      end

      # Validates that required materialized views exist before creating downloads view
      def validate_required_materialized_views_for_downloads!
        required_views_hash = Wdpa::Portal::Config::PortalImportConfig.portal_materialised_views_hash
        required_view_keys = Wdpa::Portal::Config::PortalImportConfig.required_views_for_downloads
        missing_views = []
        
        required_view_keys.each do |view_key|
          view_name = required_views_hash[view_key][:live]
          unless Wdpa::Portal::Managers::ViewManager.materialized_view_exists?(view_name)
            missing_views << view_name
          end
        end
        
        if missing_views.any?
          raise "Required materialized views missing: #{missing_views.join(', ')}. Cannot create downloads view."
        end
      end

      # Rolls back the portal downloads view to a backup version
      # Similar to rollback_portal_materialized_views: backup → live, live → staging
      def rollback_portal_download_view(backup_timestamp, log = nil)
        conn = ActiveRecord::Base.connection
        downloads_view = Wdpa::Portal::Config::PortalImportConfig::PORTAL_DOWNALOAD_VIEWS
        backup_view = Wdpa::Portal::Config::PortalImportConfig.generate_backup_name(downloads_view, backup_timestamp)
        staging_view = Wdpa::Portal::Config::PortalImportConfig.generate_staging_name(downloads_view)

        Rails.logger.info "🔄 Rolling back portal downloads view to backup #{backup_timestamp}..."

        # Step 1: Move current live to staging (if it exists)
        if conn.data_source_exists?(downloads_view)
          conn.execute("DROP VIEW IF EXISTS #{staging_view} CASCADE")
          conn.execute("ALTER VIEW #{downloads_view} RENAME TO #{staging_view}")
          Rails.logger.debug "✅ Live downloads view #{downloads_view} -> Staging view #{staging_view}"
        end

        # Step 2: Restore backup to live (if backup exists)
        if conn.data_source_exists?(backup_view)
          conn.execute("ALTER VIEW #{backup_view} RENAME TO #{downloads_view}")
          Rails.logger.info "✅ Backup downloads view #{backup_view} -> Live view #{downloads_view}"
          log&.event('portal_downloads_view_rolled_back', payload: { view: downloads_view, backup_view: backup_view, backup_timestamp: backup_timestamp })
        else
          Rails.logger.warn "⚠️ Backup downloads view #{backup_view} not found, creating fresh downloads view from rolled-back materialized views"
          # If backup doesn't exist, create a fresh view from the rolled-back materialized views
          create_portal_downloads_view!(log)
        end

        Rails.logger.info '✅ Portal downloads view rolled back'
      rescue StandardError => e
        Rails.logger.error "❌ Portal downloads view rollback failed: #{e.class}: #{e.message}"
        raise
      end
    end
  end
end
