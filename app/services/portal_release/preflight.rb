# frozen_string_literal: true

module PortalRelease
  class Preflight
    class << self
      def refresh_mvs!(log)
        return unless ActiveModel::Type::Boolean.new.cast(ENV['PP_RELEASE_REFRESH_VIEWS'])

        Wdpa::Portal::Managers::ViewManager.refresh_materialized_views
        log.event('mvs_refreshed')
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
        {
          points: conn.select_value('SELECT COUNT(*) FROM portal_standard_points').to_i,
          polygons: conn.select_value('SELECT COUNT(*) FROM portal_standard_polygons').to_i,
          sources: conn.select_value('SELECT COUNT(*) FROM portal_standard_sources').to_i
        }
      end

      def check_geometry!
        conn = ActiveRecord::Base.connection
        bad_points = conn.select_value("SELECT COUNT(*) FROM portal_standard_points WHERE wkb_geometry IS NOT NULL AND (ST_SRID(wkb_geometry) <> 4326 OR NOT ST_IsValid(wkb_geometry))").to_i
        bad_polys  = conn.select_value("SELECT COUNT(*) FROM portal_standard_polygons WHERE wkb_geometry IS NOT NULL AND (ST_SRID(wkb_geometry) <> 4326 OR NOT ST_IsValid(wkb_geometry))").to_i
        raise "Invalid geometry in views: points=#{bad_points}, polygons=#{bad_polys}" if bad_points.positive? || bad_polys.positive?
      end

      def check_duplicates!
        conn = ActiveRecord::Base.connection
        dup_points = conn.select_value(<<~SQL).to_i
          SELECT COUNT(*) FROM (
            SELECT site_id, site_pid, COUNT(*) c
            FROM portal_standard_points
            GROUP BY 1,2
            HAVING COUNT(*) > 1
          ) d
        SQL
        dup_polys = conn.select_value(<<~SQL).to_i
          SELECT COUNT(*) FROM (
            SELECT site_id, site_pid, COUNT(*) c
            FROM portal_standard_polygons
            GROUP BY 1,2
            HAVING COUNT(*) > 1
          ) d
        SQL
        raise "Duplicate rows by (site_id, site_pid): points=#{dup_points}, polygons=#{dup_polys}" if dup_points.positive? || dup_polys.positive?
      end
    end
  end
end

