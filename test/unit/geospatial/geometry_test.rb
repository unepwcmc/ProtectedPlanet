require 'test_helper'

class TestGeospatialGeometry < ActiveSupport::TestCase
 test '.merges geometries for countries with simple land geometries' do
   FactoryGirl.create(:country, iso_3: 'BAM')

   ActiveRecord::Base.connection.
     expects(:execute).
     with("""UPDATE countries
             SET land_pas_geom = a.the_geom
             FROM (
               SELECT ST_UNION(the_geom) as the_geom
               FROM 
               (SELECT  iso3, wkb_geometry the_geom FROM standard_polygons pol 
                WHERE pol.iso3 = 'BAM' AND st_isvalid(pol.wkb_geometry) 
                 AND pol.marine = '0' AND pol.status NOT IN ('Proposed', 'Not Reported')
                UNION 
                SELECT iso3, buffer_geom the_geom FROM standard_points poi
                WHERE poi.iso3 = 'BAM' AND st_isvalid(poi.buffer_geom) 
                AND poi.marine = '0' AND poi.status NOT IN ('Proposed', 'Not Reported')
                UNION
                SELECT c.iso_3, ST_Makevalid(ST_Intersection(c.land_geom,s.wkb_geometry))
                FROM standard_polygons s INNER JOIN countries c ON ST_Intersects(c.land_geom,s.wkb_geometry)
                WHERE s.iso3 LIKE '%,%' AND c.iso_3 = 'BAM' AND poi.marine = '0' AND poi.status NOT IN ('Proposed', 'Not Reported')) b) a
             WHERE iso_3 = 'BAM'""".squish).
             returns true

   ActiveRecord::Base.connection.
     expects(:execute).
     with("""UPDATE countries
             SET marine_pas_geom = a.the_geom
             FROM (
               SELECT ST_UNION(the_geom) as the_geom
               FROM 
               (SELECT  iso3, wkb_geometry the_geom FROM standard_polygons pol 
                WHERE pol.iso3 = 'BAM' AND st_isvalid(pol.wkb_geometry) 
                 AND pol.marine = '1' AND pol.status NOT IN ('Proposed', 'Not Reported')
                UNION 
                SELECT iso3, buffer_geom the_geom FROM standard_points poi
                WHERE poi.iso3 = 'BAM' AND st_isvalid(poi.buffer_geom) 
                AND poi.marine = '1' AND poi.status NOT IN ('Proposed', 'Not Reported')
                UNION
                SELECT c.iso_3, ST_Makevalid(ST_Intersection(c.land_geom,s.wkb_geometry))
                FROM standard_polygons s INNER JOIN countries c ON ST_Intersects(c.land_geom,s.wkb_geometry)
                WHERE s.iso3 LIKE '%,%' AND c.iso_3 = 'BAM' AND poi.marine = '1' AND poi.status NOT IN ('Proposed', 'Not Reported')) b) a
            WHERE iso_3 = 'BAM'""".squish).
            returns true

   geometry_operator = Geospatial::Geometry.new()
   response = geometry_operator.dissolve_countries

   assert response, 'Expects query'
  end

  test '.merges geometries for countries with complex land geometries' do
    FactoryGirl.create(:country, iso_3: 'DEU')

    ActiveRecord::Base.connection.
     expects(:execute).
     with("""UPDATE countries
             SET land_pas_geom = a.the_geom
             FROM (
               SELECT ST_UNION(the_geom) as the_geom
               FROM 
               (SELECT  iso3, ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.00000001)) the_geom 
                FROM standard_polygons pol 
                WHERE pol.iso3 = 'DEU' AND st_isvalid(pol.wkb_geometry) 
                 AND pol.marine = '0' AND pol.status NOT IN ('Proposed', 'Not Reported')
                UNION 
                SELECT iso3, buffer_geom the_geom FROM standard_points poi
                WHERE poi.iso3 = 'DEU' AND st_isvalid(poi.buffer_geom) 
                AND poi.marine = '0' AND poi.status NOT IN ('Proposed', 'Not Reported')
                UNION
                SELECT c.iso_3, ST_Makevalid(ST_Intersection(c.land_geom,s.wkb_geometry))
                FROM standard_polygons s INNER JOIN countries c ON ST_Intersects(c.land_geom,s.wkb_geometry)
                WHERE s.iso3 LIKE '%,%' AND c.iso_3 = 'DEU' AND poi.marine = '0' AND poi.status NOT IN ('Proposed', 'Not Reported')) b) a
             WHERE iso_3 = 'DEU'""".squish).
     returns true

     ActiveRecord::Base.connection.
     expects(:execute).
     with("""UPDATE countries
             SET marine_pas_geom = a.the_geom
             FROM (
               SELECT ST_UNION(the_geom) as the_geom
               FROM 
               (SELECT  iso3, wkb_geometry the_geom 
                FROM standard_polygons pol 
                WHERE pol.iso3 = 'DEU' AND st_isvalid(pol.wkb_geometry) 
                 AND pol.marine = '1' AND pol.status NOT IN ('Proposed', 'Not Reported')
                UNION 
                SELECT iso3, buffer_geom the_geom FROM standard_points poi
                WHERE poi.iso3 = 'DEU' AND st_isvalid(poi.buffer_geom) 
                AND poi.marine = '1' AND poi.status NOT IN ('Proposed', 'Not Reported')
                UNION
                SELECT c.iso_3, ST_Makevalid(ST_Intersection(c.land_geom,s.wkb_geometry))
                FROM standard_polygons s INNER JOIN countries c ON ST_Intersects(c.land_geom,s.wkb_geometry)
                WHERE s.iso3 LIKE '%,%' AND c.iso_3 = 'DEU' AND poi.marine = '1' AND poi.status NOT IN ('Proposed', 'Not Reported')) b) a
             WHERE iso_3 = 'DEU'""".squish).
     returns true

      geometry_operator = Geospatial::Geometry.new()
      response = geometry_operator.dissolve_countries

      assert response, 'Expects query'
  end

  test '.splits geometries for pas in eez and ts marine areas' do
    FactoryGirl.create(:country, iso_3: 'BUM')

    ActiveRecord::Base.connection.
    expects(:execute).
    with("""
      UPDATE countries SET marine_ts_pas_geom = (
        SELECT CASE
            WHEN ST_Within(marine_pas_geom, ts_geom)
            THEN marine_pas_geom
            ELSE ST_Intersection(marine_pas_geom, ts_geom)
         END
        FROM countries
        WHERE iso_3 = 'BUM' LIMIT 1 
      )
      WHERE iso_3 = 'BUM'
    """.squish).
    returns true

    ActiveRecord::Base.connection.
    expects(:execute).
    with("""
      UPDATE countries SET marine_eez_pas_geom = (
        SELECT CASE
            WHEN ST_Within(marine_pas_geom, eez_geom)
            THEN marine_pas_geom
            ELSE ST_Intersection(marine_pas_geom, eez_geom)
         END
        FROM countries
        WHERE iso_3 = 'BUM' LIMIT 1 
      )
      WHERE iso_3 = 'BUM'
    """.squish).
    returns true

    geometry_operator = Geospatial::Geometry.new()
    response = geometry_operator.split_countries_marine

    assert response, 'Expects query'
  end

  test '.updates buffer_geom field on standard_points' do
    ActiveRecord::Base.connection.
     expects(:execute).
     with("""UPDATE standard_points
             SET buffer_geom = ST_Buffer(wkb_geometry::geography, |/( rep_area*1000000 / pi() ))::geometry
             WHERE rep_area IS NOT NULL OR wdpaid NOT IN (18293, 34878);""".squish).
     returns true
    geometry_operator = Geospatial::Geometry.new()
    response = geometry_operator.create_buffers
    assert response, 'Expects query'
  end
end
