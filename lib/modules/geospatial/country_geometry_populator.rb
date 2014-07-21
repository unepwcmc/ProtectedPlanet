module Geospatial::CountryGeometryPopulator
  DISSOLVE_GEOMETRIES_TEMPLATE = File.expand_path(
    File.join('../templates', 'dissolve_geometries.erb'), __FILE__
  )

  MARINE_GEOMETRIES_TEMPLATE = File.expand_path(
    File.join('../templates', 'marine_geometry.erb'), __FILE__
  )

  AREA_TYPES = {
    'marine' => 1,
    'land' => 0
  }

  def self.populate_dissolved_geometries country
    AREA_TYPES.each do |area_type, marine_status|
      DB.execute render_template(DISSOLVE_GEOMETRIES_TEMPLATE, binding)
    end
  end

  MARINE_TYPES = ['eez', 'ts']

  def self.populate_marine_geometries country
    MARINE_TYPES.each do |marine_type|
      DB.execute render_template(MARINE_GEOMETRIES_TEMPLATE, binding)
    end
  end

  private

  DB = ActiveRecord::Base.connection

  def self.render_template template_path, binding
    template = ERB.new(File.read(template_path))
    template.result(binding).squish
  end

  COMPLEX_COUNTRIES = {
    'marine' => ['GBR'],
    'land'   => ['DEU','USA','FRA','GBR','AUS','FIN','BGR','CAN',
                 'ESP','SWE','BEL','EST','IRL','ITA','LTU',
                 'NZL','POL','CHE']
  }

  def self.geometry_attribute country, area_type
    if COMPLEX_COUNTRIES[area_type].include? country.iso_3
      'ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.00000001))'
    else
      'wkb_geometry'
    end
  end

  COUNTRIES_WITH_TOPOLOGY_PROBLEMS = [
    'USA','RUS','HRV','CAN','MYS','THA','GNQ','COL','JPN',
    'ESP','NIC','KOR','EGY'
  ]

  def self.country_needs_simplifying? country
    ['HRV', 'THA', 'JPN', 'KOR'].include? country.iso_3
  end

  def self.marine_geometry_attributes country, area_type
    if COUNTRIES_WITH_TOPOLOGY_PROBLEMS.include? country.iso_3
      [
        'ST_MakeValid(ST_Buffer(ST_Simplify(marine_pas_geom,0.005),0.00000001))',
        "ST_MakeValid(ST_Buffer(ST_Simplify(#{area_type}_geom,0.005),0.00000001))"
      ]
    else
      ['marine_pas_geom', "#{area_type}_geom"]
    end
  end
end
