module Geospatial::CountryGeometryPopulator

  def self.repair_geometries
    GeometryRepairer.repair
  end

  def self.populate_dissolved_geometries country
    GeometryDissolver.dissolve country
  end

  def self.populate_marine_geometries country
    MarineGeometriesIntersector.intersect country
  end
end
