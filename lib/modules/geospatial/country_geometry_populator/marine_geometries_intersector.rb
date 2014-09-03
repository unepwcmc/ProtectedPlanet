module Geospatial::CountryGeometryPopulator::MarineGeometriesIntersector

  INTERSECTOR_TEMPLATE = File.expand_path(
    File.join('../../templates', 'marine_geometry.erb'), __FILE__
  )

  MARINE_TYPES = ['eez', 'ts']

  def self.intersect country
    repair_marine_geometries

    MARINE_TYPES.each do |marine_type|
      db.execute render_template(INTERSECTOR_TEMPLATE, binding)
    end
  end

  private

  def self.db
    ActiveRecord::Base.connection
  end

  def self.render_template template_path, binding
    template = ERB.new(File.read(template_path))
    template.result(binding).squish
  end

  def self.repair_marine_geometries
    geometry = Geospatial::Geometry.new 'countries', 'marine_pas_geom'
    geometry.repair
  end

  def self.marine_geometry_attributes area_type
    "#{area_type}_geom"
  end
end
