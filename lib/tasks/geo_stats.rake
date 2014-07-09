namespace :geo_stats do
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
    column_prefix = type == 1 ? 'marine' : 'land'
    query = "UPDATE countries
             SET #{column_prefix}_pas_geom = a.the_geom
             FROM (SELECT ST_UNION(#{geometry}) as the_geom
             FROM standard_polygons
             WHERE iso3 = '#{country}' AND st_isvalid(wkb_geometry) AND marine = '#{type}') a
             WHERE iso_3 = '#{country}'"
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