require 'test_helper'

class CountryGeometryPopulatorTest < ActiveSupport::TestCase
  test '#dissolve, given a country, dissolves the marine and terrestrial
   geometries' do
    country = FactoryGirl.build(:country, iso_3: 'FAK')

    marine_query = """
      UPDATE countries
      SET marine_pas_geom = a.the_geom
      FROM (
       SELECT ST_UNION(the_geom) as the_geom
       FROM (
         SELECT  iso3, wkb_geometry the_geom FROM standard_polygons pol
           WHERE pol.iso3 = 'FAK'
            AND st_isvalid(pol.wkb_geometry)
            AND pol.marine = '1'
            AND pol.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT iso3, buffer_geom the_geom FROM standard_points poi
           WHERE poi.iso3 = 'FAK'
            AND st_isvalid(poi.buffer_geom)
            AND poi.marine = '1'
            AND poi.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT c.iso_3, ST_Makevalid(ST_Intersection(c.land_geom,s.wkb_geometry)) FROM standard_polygons s
           INNER JOIN countries c ON ST_Intersects(c.land_geom,s.wkb_geometry)
           WHERE s.iso3 LIKE '%,%'
            AND c.iso_3 = 'FAK'
            AND poi.marine = '1'
            AND poi.status NOT IN ('Proposed', 'Not Reported')
        ) b
      ) a
      WHERE iso_3 = 'FAK'
    """.squish

    land_query = """
      UPDATE countries
      SET land_pas_geom = a.the_geom
      FROM (
       SELECT ST_UNION(the_geom) as the_geom
       FROM (
         SELECT  iso3, wkb_geometry the_geom FROM standard_polygons pol
           WHERE pol.iso3 = 'FAK'
            AND st_isvalid(pol.wkb_geometry)
            AND pol.marine = '0'
            AND pol.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT iso3, buffer_geom the_geom FROM standard_points poi
           WHERE poi.iso3 = 'FAK'
            AND st_isvalid(poi.buffer_geom)
            AND poi.marine = '0'
            AND poi.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT c.iso_3, ST_Makevalid(ST_Intersection(c.land_geom,s.wkb_geometry)) FROM standard_polygons s
           INNER JOIN countries c ON ST_Intersects(c.land_geom,s.wkb_geometry)
           WHERE s.iso3 LIKE '%,%'
            AND c.iso_3 = 'FAK'
            AND poi.marine = '0'
            AND poi.status NOT IN ('Proposed', 'Not Reported')
        ) b
      ) a
      WHERE iso_3 = 'FAK'
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(marine_query)
    ActiveRecord::Base.connection.expects(:execute).with(land_query)

    Geospatial::CountryGeometryPopulator.populate_dissolved_geometries country
  end

  test '#dissolve, given a country defined as "complex", simplifies the
   terrestrial geometry' do
    country = FactoryGirl.build(:country, iso_3: 'AUS')

    marine_query = """
      UPDATE countries
      SET marine_pas_geom = a.the_geom
      FROM (
       SELECT ST_UNION(the_geom) as the_geom
       FROM (
         SELECT  iso3, wkb_geometry the_geom FROM standard_polygons pol
           WHERE pol.iso3 = 'AUS'
            AND st_isvalid(pol.wkb_geometry)
            AND pol.marine = '1'
            AND pol.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT iso3, buffer_geom the_geom FROM standard_points poi
           WHERE poi.iso3 = 'AUS'
            AND st_isvalid(poi.buffer_geom)
            AND poi.marine = '1'
            AND poi.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT c.iso_3, ST_Makevalid(ST_Intersection(c.land_geom,s.wkb_geometry)) FROM standard_polygons s
           INNER JOIN countries c ON ST_Intersects(c.land_geom,s.wkb_geometry)
           WHERE s.iso3 LIKE '%,%'
            AND c.iso_3 = 'AUS'
            AND poi.marine = '1'
            AND poi.status NOT IN ('Proposed', 'Not Reported')
        ) b
      ) a
      WHERE iso_3 = 'AUS'
    """.squish

    land_query = """
      UPDATE countries
      SET land_pas_geom = a.the_geom
      FROM (
       SELECT ST_UNION(the_geom) as the_geom
       FROM (
         SELECT  iso3, ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.00000001)) the_geom FROM standard_polygons pol
           WHERE pol.iso3 = 'AUS'
            AND st_isvalid(pol.wkb_geometry)
            AND pol.marine = '0'
            AND pol.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT iso3, buffer_geom the_geom FROM standard_points poi
           WHERE poi.iso3 = 'AUS'
            AND st_isvalid(poi.buffer_geom)
            AND poi.marine = '0'
            AND poi.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT c.iso_3, ST_Makevalid(ST_Intersection(c.land_geom,s.wkb_geometry)) FROM standard_polygons s
           INNER JOIN countries c ON ST_Intersects(c.land_geom,s.wkb_geometry)
           WHERE s.iso3 LIKE '%,%'
            AND c.iso_3 = 'AUS'
            AND poi.marine = '0'
            AND poi.status NOT IN ('Proposed', 'Not Reported')
        ) b
      ) a
      WHERE iso_3 = 'AUS'
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(marine_query)
    ActiveRecord::Base.connection.expects(:execute).with(land_query)

    Geospatial::CountryGeometryPopulator.populate_dissolved_geometries country
  end

  test '#dissolve, given a country defined as "complex", simplifies the
   marine geometry' do
    country = FactoryGirl.build(:country, iso_3: 'GBR')

    marine_query = """
      UPDATE countries
      SET marine_pas_geom = a.the_geom
      FROM (
       SELECT ST_UNION(the_geom) as the_geom
       FROM (
         SELECT  iso3, ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.00000001)) the_geom FROM standard_polygons pol
           WHERE pol.iso3 = 'GBR'
            AND st_isvalid(pol.wkb_geometry)
            AND pol.marine = '1'
            AND pol.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT iso3, buffer_geom the_geom FROM standard_points poi
           WHERE poi.iso3 = 'GBR'
            AND st_isvalid(poi.buffer_geom)
            AND poi.marine = '1'
            AND poi.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT c.iso_3, ST_Makevalid(ST_Intersection(c.land_geom,s.wkb_geometry)) FROM standard_polygons s
           INNER JOIN countries c ON ST_Intersects(c.land_geom,s.wkb_geometry)
           WHERE s.iso3 LIKE '%,%'
            AND c.iso_3 = 'GBR'
            AND poi.marine = '1'
            AND poi.status NOT IN ('Proposed', 'Not Reported')
        ) b
      ) a
      WHERE iso_3 = 'GBR'
    """.squish

    land_query = """
      UPDATE countries
      SET land_pas_geom = a.the_geom
      FROM (
       SELECT ST_UNION(the_geom) as the_geom
       FROM (
         SELECT  iso3, ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.00000001)) the_geom FROM standard_polygons pol
           WHERE pol.iso3 = 'GBR'
            AND st_isvalid(pol.wkb_geometry)
            AND pol.marine = '0'
            AND pol.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT iso3, buffer_geom the_geom FROM standard_points poi
           WHERE poi.iso3 = 'GBR'
            AND st_isvalid(poi.buffer_geom)
            AND poi.marine = '0'
            AND poi.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT c.iso_3, ST_Makevalid(ST_Intersection(c.land_geom,s.wkb_geometry)) FROM standard_polygons s
           INNER JOIN countries c ON ST_Intersects(c.land_geom,s.wkb_geometry)
           WHERE s.iso3 LIKE '%,%'
            AND c.iso_3 = 'GBR'
            AND poi.marine = '0'
            AND poi.status NOT IN ('Proposed', 'Not Reported')
        ) b
      ) a
      WHERE iso_3 = 'GBR'
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(marine_query)
    ActiveRecord::Base.connection.expects(:execute).with(land_query)

    Geospatial::CountryGeometryPopulator.populate_dissolved_geometries country
  end
end
