module Geospatial::CountryGeometryPopulator::GeometryRepairer

  TEMPLATE = File.expand_path(
    File.join('../../templates', 'repair_geometries.erb'), __FILE__
  )

  COLUMN_NAME = 'wkb_geometry'
  TABLE_NAME = 'standard_polygons'

  def self.repair
    DB.execute render_template(TEMPLATE)
  end

  private

  DB = ActiveRecord::Base.connection

  def self.render_template template_path
    column_name = COLUMN_NAME
    table_name = TABLE_NAME
    template = ERB.new(File.read(template_path))
    template.result(binding).squish
  end
end