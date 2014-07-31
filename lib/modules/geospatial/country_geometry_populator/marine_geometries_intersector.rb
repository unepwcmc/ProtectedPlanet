module Geospatial::CountryGeometryPopulator::MarineGeometriesIntersector

  REPAIRER_TEMPLATE = File.expand_path(
    File.join('../../templates', 'repair_geometries.erb'), __FILE__
  )

  INTERSECTOR_TEMPLATE = File.expand_path(
    File.join('../../templates', 'marine_geometry.erb'), __FILE__
  )

  MARINE_TYPES = ['eez', 'ts']

  TABLE_NAME = 'countries'
  COLUMN_NAME = 'marine_pas_geom'

  def self.intersect country
    column_name = COLUMN_NAME
    table_name = TABLE_NAME
    DB.execute render_template(REPAIRER_TEMPLATE, binding)
    MARINE_TYPES.each do |marine_type|
      DB.execute render_template(INTERSECTOR_TEMPLATE, binding)
    end
  end

  private

  DB = ActiveRecord::Base.connection

  def self.render_template template_path, binding
    template = ERB.new(File.read(template_path))
    template.result(binding).squish
  end


  def self.marine_geometry_attributes area_type
    "#{area_type}_geom"
  end
end
