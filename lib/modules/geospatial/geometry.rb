class Geospatial::Geometry
  def initialize
    @complex_countries_land = ['DEU','USA','FRA','GBR','AUS','FIN','BGR', 'CAN', 'ESP','SWE','BEL','EST', 'IRL', 'ITA', 'LTU', 'NZL','POL','CHE']
    @complex_countries_marine = ['GBR']
    @iso3_codes = Country.pluck(:iso_3)
  end

  def dissolve_countries
    marine = [0,1]
    marine.each do |marine_area|
      @iso3_codes.each do |country|
        if marine_area == 0 
          type = 'Terrestrial'
          geometry = complex_geometries(country,false)
        else
          type = 'Marine'
          geometry = complex_geometries(country,true)
        end
        dissolve_country(country,marine_area,geometry)
      end
    end
  end

  def split_countries_marine
    @iso3_codes.each do |country|
      split_country_marine country
    end
  end

  def create_buffers
    query = """UPDATE standard_points
      SET buffer_geom = ST_Buffer(wkb_geometry::geography, |/( rep_area*1000000 / pi() ))::geometry
      WHERE rep_area IS NOT NULL OR wdpaid NOT IN (18293, 34878);""".squish
    db_execute query
  end

  private

  DB = ActiveRecord::Base.connection

  def db_execute query
    DB.execute(query)
  end

  def dissolve_country country, type, geometry
    column_prefix = type == 1 ? 'marine' : 'land'
    query = """
      UPDATE countries
      SET #{column_prefix}_pas_geom = a.the_geom
      FROM (
       SELECT ST_UNION(the_geom) as the_geom
       FROM 
        (SELECT  iso3, #{geometry} the_geom FROM standard_polygons pol 
          WHERE pol.iso3 = '#{country}' AND st_isvalid(pol.wkb_geometry) 
          AND pol.marine = '#{type}' AND pol.status NOT IN ('Proposed', 'Not Reported')
          UNION 
          SELECT iso3, buffer_geom the_geom FROM standard_points poi
          WHERE poi.iso3 = '#{country}' AND st_isvalid(poi.buffer_geom) 
          AND poi.marine = '#{type}' AND poi.status NOT IN ('Proposed', 'Not Reported')
          UNION
          SELECT c.iso_3, ST_Makevalid(ST_Intersection(c.land_geom,s.wkb_geometry))
          FROM standard_polygons s INNER JOIN countries c ON ST_Intersects(c.land_geom,s.wkb_geometry)
          WHERE s.iso3 LIKE '%,%' AND c.iso_3 = '#{country}' 
          AND poi.marine = '#{type}' AND poi.status NOT IN ('Proposed', 'Not Reported')) b) a
      WHERE iso_3 = '#{country}'""".squish
    db_execute query
  end

  def split_country_marine country
    ['eez', 'ts'].each do |marine_type|

      # Countries with topology problems...
      unless ['USA', 'RUS', 'HRV', 'CAN', 'MYS', 'THA', 'GNQ', 'COL', 'JPN', 'ESP', 'NIC', 'KOR', 'EGY'].include? country
        partial = "marine_pas_geom, #{marine_type}_geom"
      else
        partial = """
          ST_MakeValid(ST_Buffer(ST_Simplify(marine_pas_geom,0.005),0.00000001)), 
          ST_MakeValid(ST_Buffer(ST_Simplify(#{marine_type}_geom,0.005),0.00000001))
        """.squish
      end
      # Further, unresolved topology problems...
      if ['HRV', 'THA', 'JPN', 'KOR'].include? country
        query = """
          UPDATE countries SET marine_#{marine_type}_pas_geom = (
          SELECT ST_MakeValid(ST_Intersection(#{partial}))
          FROM countries
          WHERE iso_3 = '#{country}' LIMIT 1 
          )
          WHERE iso_3 = '#{country}'
        """.squish
      else
        query = """
          UPDATE countries SET marine_#{marine_type}_pas_geom = (
          SELECT CASE
            WHEN ST_Within(marine_pas_geom, #{marine_type}_geom)
            THEN marine_pas_geom
            ELSE ST_Intersection(#{partial})
          END
          FROM countries
          WHERE iso_3 = '#{country}' LIMIT 1 
          )
          WHERE iso_3 = '#{country}'
        """.squish
      end
      db_execute query
    end
  end

  def complex_geometries iso3, marine
    complex_countries = marine ? @complex_countries_marine : @complex_countries_land
    geometry = complex_countries.include?(iso3) ? 'ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.00000001))' : 'wkb_geometry'
    geometry
  end

end
