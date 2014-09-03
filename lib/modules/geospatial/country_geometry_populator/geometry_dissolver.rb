module Geospatial::CountryGeometryPopulator::GeometryDissolver
  TEMPLATE = File.expand_path(
    File.join('../../templates', 'dissolve_geometries.erb'), __FILE__
  )

  AREA_TYPES = {
    'marine' => 1,
    'land' => 0
  }

  def self.dissolve country
    AREA_TYPES.each do |area_type, marine_status|
      db.execute render_template(TEMPLATE, binding)
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

  COMPLEX_COUNTRIES = {
    'marine' => ['GBR','USA','CAN','MYT','CIV','AUS'],
    'land'   => ['DEU','USA','FRA','GBR','AUS','FIN','BGR','CAN',
                 'ESP','SWE','BEL','EST','IRL','ITA','LTU',
                 'NZL','POL','CHE']
  }

  def self.geometry_attribute country, area_type
    if COMPLEX_COUNTRIES[area_type].include? country.iso_3
      'ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.0))'
    else
      'wkb_geometry'
    end
  end
end
