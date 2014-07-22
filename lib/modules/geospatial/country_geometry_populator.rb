module Geospatial::CountryGeometryPopulator
  def self.populate_dissolved_geometries country
    GeometryDissolver.dissolve country
  end

  def self.populate_marine_geometries country
    MarineGeometriesIntersector.intersect country
  end
end
