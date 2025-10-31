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

        conn.transaction do
          # Drop all temporary download views that depends on the downloads view
          Download.clear_downloads

          conn.execute("DROP VIEW IF EXISTS #{downloads_view}")
          as_query = Download::Queries.build_query_for_downloads_view('portal')

          conn.execute("CREATE VIEW #{downloads_view} AS (SELECT #{as_query[:select]} FROM #{as_query[:from]})")
          log&.event('portal_downloads_view_created', payload: { view: downloads_view })
        end
      end
    end
  end
end
