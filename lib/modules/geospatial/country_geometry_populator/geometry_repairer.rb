module Geospatial::CountryGeometryPopulator::GeometryRepairer
  def self.repair
    DB.execute repair_query
  end

  private

  DB = ActiveRecord::Base.connection

  def self.repair_query
    """UPDATE standard_polygons
       SET wkb_geometry = ST_Makevalid(ST_Multi(ST_Buffer(wkb_geometry,0.0)))
       WHERE NOT ST_IsValid(wkb_geometry)""".squish
  end

end