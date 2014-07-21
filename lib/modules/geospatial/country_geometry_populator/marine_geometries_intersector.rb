module Geospatial::CountryGeometryPopulator::MarineGeometriesIntersector
  TEMPLATE = File.expand_path(
    File.join('../../templates', 'marine_geometry.erb'), __FILE__
  )

  MARINE_TYPES = ['eez', 'ts']

  def self.intersect country
    MARINE_TYPES.each do |marine_type|
      DB.execute render_template(TEMPLATE, binding)
    end
  end

  private

  DB = ActiveRecord::Base.connection

  def self.render_template template_path, binding
    template = ERB.new(File.read(template_path))
    template.result(binding).squish
  end

  COUNTRIES_WITH_TOPOLOGY_PROBLEMS = [
    'USA','RUS','HRV','CAN','MYS','THA','GNQ','COL','JPN',
    'ESP','NIC','KOR','EGY','MAR'
  ]

  def self.country_needs_simplifying? country
    ['HRV', 'THA', 'JPN', 'KOR', 'MAR'].include? country.iso_3
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
