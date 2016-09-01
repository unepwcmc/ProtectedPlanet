module Wdpa::GeometryRatioCalculator
  def self.calculate
    Country.pluck(:id).each do |country_id|
      geometry_counts = calculate_geometry_counts(country_id)

      statistics = CountryStatistic.find_or_initialize_by(country_id: country_id)
      statistics.polygons_count = geometry_counts["polygons"]
      statistics.points_count = geometry_counts["points"]

      statistics.save
    end
  end

  def self.calculate_geometry_counts country_id
    ActiveRecord::Base.connection.select_all("""
      SELECT
        SUM((CASE WHEN GeometryType(the_geom) = 'MULTIPOINT' THEN 1 ELSE 0 END)) AS points,
        SUM((CASE WHEN GeometryType(the_geom) = 'MULTIPOLYGON' THEN 1 ELSE 0 END)) AS polygons
      FROM protected_areas pas
      INNER JOIN
        countries_protected_areas cpas
        ON cpas.protected_area_id = pas.id
        AND cpas.country_id = #{country_id}
    """).first
  end
end
