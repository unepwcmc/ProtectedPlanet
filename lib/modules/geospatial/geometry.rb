class Geospatial::Geometry

  def initialize complex_countries_land, complex_countries_marine
    @complex_countries_land = complex_countries_land
    @complex_countries_marine = complex_countries_marine
    @iso3_codes = Country.pluck(:iso_3)
  end

  def drop_indexes
    query = """
      DROP INDEX IF EXISTS land_pas_geom_gindx;
      DROP INDEX IF EXISTS marine_pas_geom_gindx;
      DROP INDEX IF EXISTS marine_ts_pas_geom_gindx;
      DROP INDEX IF EXISTS marine_ts_eez_geom_gindx;
    """.squish
    db_execute query
  end

  def create_indexes
    query = """
      CREATE INDEX land_pas_geom_gindx ON countries USING GIST (land_pas_geom);
      CREATE INDEX marine_pas_geom_gindx ON countries USING GIST (marine_pas_geom);
      CREATE INDEX marine_ts_pas_geom_gindx ON countries USING GIST (marine_ts_pas_geom);
      CREATE INDEX marine_eez_pas_geom_gindx ON countries USING GIST (marine_eez_pas_geom);
    """.squish
    db_execute query
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
        puts "Dissolving #{type} #{country}"
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
    query = """UPDATE countries
             SET #{column_prefix}_pas_geom = a.the_geom
             FROM (
              SELECT ST_UNION(the_geom) as the_geom
              FROM 
               (SELECT  iso3, #{geometry} the_geom FROM standard_polygons pol 
                WHERE pol.iso3 = '#{country}' AND st_isvalid(pol.wkb_geometry) AND pol.marine = '#{type}'
                UNION 
                SELECT iso3, buffer_geom the_geom FROM standard_points poi
                WHERE poi.iso3 = '#{country}' AND st_isvalid(poi.buffer_geom) AND poi.marine = '#{type}') b) a
             WHERE iso_3 = '#{country}'""".squish
    db_execute query
  end

  def split_country_marine country
    ['eez', 'ts'].each do |marine_type|
      query = """
        UPDATE countries SET marine_#{marine_type}_pas_geom = (
        SELECT CASE
            WHEN ST_Within(marine_pas_geom, #{marine_type}_geom)
            THEN marine_pas_geom
            ELSE ST_Multi(ST_Intersection(marine_pas_geom, #{marine_type}_geom))
         END
        FROM countries
        WHERE iso_3 = '#{country}'
        )
        WHERE iso_3 = '#{country}'
      """.squish
      db_execute query
    end
  end

  def complex_geometries iso3, marine
    complex_countries = marine ? @complex_countries_marine : @complex_countries_land
    geometry = complex_countries.include?(iso3) ? 'ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.00000001))' : 'wkb_geometry'
    geometry
  end

end