module Wdpa::Portal::Importers
  class CountriesProtectedAreaGeometryStatistics
    def self.calculate
      country_ids = Country.pluck(:id)
      processed_countries_count = 0
      errors = []

      country_ids.each do |country_id|
        geometry_counts = calculate_country_pas_geometry_counts(country_id)
        statistics = Staging::CountryStatistic.find_or_initialize_by(country_id: country_id)
        statistics.assign_attributes(geometry_counts)
        statistics.save
        processed_countries_count += 1
      rescue StandardError => e
        errors << "Country ID #{country_id}: #{e.message}"
      end

      Rails.logger.info "Country geometry statistics calculation completed: #{processed_countries_count} countries processed"

      {
        success: errors.empty?,
        processed_countries_count: processed_countries_count,
        errors: errors
      }
    end

    def self.calculate_country_pas_geometry_counts(country_id)
      staging_protected_areas_table = Staging::ProtectedArea.table_name
      staging_countries_protected_areas_table = Wdpa::Portal::Config::StagingConfig.get_staging_table_name_from_live_table('countries_protected_areas')
      statics_query = <<~SQL
        SELECT
          COALESCE(SUM((CASE WHEN GeometryType(the_geom) IN ('MULTIPOINT', 'POINT') THEN 1 ELSE 0 END)), 0) AS points_count,
          COALESCE(SUM((CASE WHEN GeometryType(the_geom) IN ('MULTIPOLYGON', 'POLYGON') THEN 1 ELSE 0 END)), 0) AS polygons_count,
          COALESCE(SUM((CASE WHEN GeometryType(the_geom) IN ('MULTIPOLYGON', 'POLYGON') AND pas.is_oecm = true THEN 1 ELSE 0 END)), 0) AS oecm_polygon_count,
          COALESCE(SUM((CASE WHEN GeometryType(the_geom) IN ('MULTIPOINT', 'POINT') AND pas.is_oecm = true THEN 1 ELSE 0 END)), 0) AS oecm_point_count,
          COALESCE(SUM((CASE WHEN GeometryType(the_geom) IN ('MULTIPOLYGON', 'POLYGON') AND pas.is_oecm = false THEN 1 ELSE 0 END)), 0) AS protected_area_polygon_count,
          COALESCE(SUM((CASE WHEN GeometryType(the_geom) IN ('MULTIPOINT', 'POINT') AND pas.is_oecm = false THEN 1 ELSE 0 END)), 0) AS protected_area_point_count
        FROM #{staging_protected_areas_table} pas
        INNER JOIN
          #{staging_countries_protected_areas_table} cpas
          ON cpas.protected_area_id = pas.id
          AND cpas.country_id = #{country_id}
      SQL
      result = ActiveRecord::Base.connection.select_all(statics_query).first

      # Ensure all counts are integers (not nil)
      result.transform_values { |v| v.nil? ? 0 : v.to_i }
    end
  end
end
