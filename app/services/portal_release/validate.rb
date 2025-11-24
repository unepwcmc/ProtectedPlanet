# frozen_string_literal: true

module PortalRelease
  class Validate
    def initialize(release, log)
      @release = release
      @log = log
    end

    def run!
      # Compare counts between portal views and staging tables (rough sanity)
      src = source_counts
      dst = staging_counts

      # These aren’t 1:1 (parcels vs areas), so use basic guards
      raise 'No protected areas imported' if dst[:protected_areas].zero?
      raise 'No sources imported' if dst[:sources].zero?

      geom_ok = geometry_presence_ok?
      raise 'No geometries updated in staging tables' unless geom_ok

      merged = (@release.stats_json || {}).merge({ dst_counts: dst, src_counts: src })
      @release.update!(state: 'validating', stats_json: merged)
      @log.event('validate_ok', payload: { src: src, dst: dst })
    end

    private

    def c(sql)
      ActiveRecord::Base.connection.select_value(sql).to_i
    end

    def source_counts
      staging_views = Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views
      {
        points: c("SELECT COUNT(*) FROM #{staging_views[:points]}"),
        polygons: c("SELECT COUNT(*) FROM #{staging_views[:polygons]}"),
        sources: c("SELECT COUNT(*) FROM #{staging_views[:sources]}")
      }
    end

    def staging_counts
      {
        protected_areas: c("SELECT COUNT(*) FROM #{::Staging::ProtectedArea.table_name}"),
        protected_area_parcels: c("SELECT COUNT(*) FROM #{::Staging::ProtectedAreaParcel.table_name}"),
        sources: c("SELECT COUNT(*) FROM #{::Staging::Source.table_name}")
      }
    end

    def geometry_presence_ok?
      pa_geom = c("SELECT COUNT(*) FROM #{::Staging::ProtectedArea.table_name} WHERE the_geom IS NOT NULL")
      parcel_geom = c("SELECT COUNT(*) FROM #{::Staging::ProtectedAreaParcel.table_name} WHERE the_geom IS NOT NULL")
      (pa_geom + parcel_geom) > 0
    end
  end
end
