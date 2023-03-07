module Wdpa::GeometryRatioCalculator
  # This class does not appear to calculate ratios, rather it counts the number of points and polygons for each country.
  # It is run during the WDPA import process and updates the fields according to the new WPDA data.
  # It has been modified to also count the number of PA and OECM points and polygons for each country.
  def self.calculate
    Country.pluck(:id).each do |country_id|
      geometry_counts = calculate_geometry_counts(country_id)

      statistics = CountryStatistic.find_or_initialize_by(country_id: country_id)
      statistics.assign_attributes(geometry_counts)
      statistics.save
    end
  end

  def self.calculate_geometry_counts country_id
    ActiveRecord::Base.connection.select_all("""
      SELECT
        SUM((CASE WHEN GeometryType(the_geom) = 'MULTIPOINT' THEN 1 ELSE 0 END)) AS points_count,
        SUM((CASE WHEN GeometryType(the_geom) = 'MULTIPOLYGON' THEN 1 ELSE 0 END)) AS polygons_count,
        SUM((CASE WHEN GeometryType(the_geom) = 'MULTIPOLYGON' AND pas.is_oecm = true THEN 1 ELSE 0 END)) AS oecm_polygon_count,
        SUM((CASE WHEN GeometryType(the_geom) = 'MULTIPOINT' AND pas.is_oecm = true THEN 1 ELSE 0 END)) AS oecm_point_count,
        SUM((CASE WHEN GeometryType(the_geom) = 'MULTIPOLYGON' AND pas.is_oecm = false THEN 1 ELSE 0 END)) AS protected_area_polygon_count,
        SUM((CASE WHEN GeometryType(the_geom) = 'MULTIPOINT' AND pas.is_oecm = false THEN 1 ELSE 0 END)) AS protected_area_point_count
      FROM protected_areas pas
      INNER JOIN
        countries_protected_areas cpas
        ON cpas.protected_area_id = pas.id
        AND cpas.country_id = #{country_id}
      """).first
  end
end
