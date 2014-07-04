namespace :geo_stats do
  COMPLEX_COUNTRIES_LAND = ['DEU','USA','FRA','GBR','AUS','FIN','BGR', 'CAN', 'ESP','SWE','BEL','EST', 'IRL', 'ITA', 'LTU', 'NZL','POL','CHE']
  COMPLEX_COUNTRIES_MARINE = ['GBR']
  desc "Generate Country Flat protected_Areas"
  task country_dissolve: :environment do
    DB = ActiveRecord::Base.connection
    iso3 = Country.pluck(:iso_3)
    marine = [0,1]
    marine.each do |marine_area|
      iso3.each do |country|
        if marine_area == 0 
          type = 'Terrestrial'
          geometry = complex_geometries(country,false)
        else
          type = 'Marine'
          geometry = complex_geometries(country,true)
        end
        puts "Dissolving #{type} #{country}"
        sql = query(country,marine_area,geometry)
        DB.execute(sql)
      end
    end
  end

  def query country, type, geometry
    marine = type == 1 ? true : false
    query = "INSERT INTO countries_pas_geom(iso3, the_geom, marine) 
             SELECT '#{country}', ST_UNION(#{geometry}),  #{marine}
             FROM wdpapoly_june2014
             WHERE iso3 = '#{country}' AND st_isvalid(wkb_geometry) AND marine = '#{type}'"
    query
  end

  def complex_geometries iso3,marine
    complex_countries_land = ['DEU','USA','FRA','GBR','AUS','FIN','BGR', 'CAN', 'ESP','SWE','BEL','EST', 'IRL', 'ITA', 'LTU', 'NZL','POL','CHE']
    complex_countries_marine = ['GBR']
    complex_countries = marine ? complex_countries_marine : complex_countries_land
    geometry = complex_countries.include?(iso3) ? 'ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.00000001))' : 'wkb_geometry'
    geometry
  end
end