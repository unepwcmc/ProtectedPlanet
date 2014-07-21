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
         SELECT  iso3, wkb_geometry the_geom FROM standard_polygons polygon
           WHERE polygon.iso3 = 'FAK'
            AND ST_IsValid(polygon.wkb_geometry)
            AND polygon.marine = '1'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT iso3, the_geom FROM (
           SELECT iso3, ST_Buffer(wkb_geometry::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
           FROM standard_points point
           WHERE point.iso3 = 'FAK'
             AND point.marine = '1'
             AND point.status NOT IN ('Proposed', 'Not Reported')
         ) AS c
         WHERE ST_IsValid(the_geom)

         UNION

         SELECT country.iso_3, ST_Makevalid(ST_Intersection(country.land_geom, polygon.wkb_geometry)) FROM standard_polygons polygon
           INNER JOIN countries country ON ST_Intersects(country.land_geom, polygon.wkb_geometry)
           WHERE polygon.iso3 LIKE '%,%'
            AND country.iso_3 = 'FAK'
            AND polygon.marine = '1'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')
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
         SELECT  iso3, wkb_geometry the_geom FROM standard_polygons polygon
           WHERE polygon.iso3 = 'FAK'
            AND ST_IsValid(polygon.wkb_geometry)
            AND polygon.marine = '0'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT iso3, the_geom FROM (
           SELECT iso3, ST_Buffer(wkb_geometry::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
           FROM standard_points point
           WHERE point.iso3 = 'FAK'
             AND point.marine = '0'
             AND point.status NOT IN ('Proposed', 'Not Reported')
         ) AS c
         WHERE ST_IsValid(the_geom)

         UNION

         SELECT country.iso_3, ST_Makevalid(ST_Intersection(country.land_geom, polygon.wkb_geometry)) FROM standard_polygons polygon
           INNER JOIN countries country ON ST_Intersects(country.land_geom, polygon.wkb_geometry)
           WHERE polygon.iso3 LIKE '%,%'
            AND country.iso_3 = 'FAK'
            AND polygon.marine = '0'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')
        ) b
      ) a
      WHERE iso_3 = 'FAK'
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
         SELECT  iso3, ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.00000001)) the_geom FROM standard_polygons polygon
           WHERE polygon.iso3 = 'GBR'
            AND ST_IsValid(polygon.wkb_geometry)
            AND polygon.marine = '1'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT iso3, the_geom FROM (
           SELECT iso3, ST_Buffer(wkb_geometry::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
           FROM standard_points point
           WHERE point.iso3 = 'GBR'
             AND point.marine = '1'
             AND point.status NOT IN ('Proposed', 'Not Reported')
         ) AS c
         WHERE ST_IsValid(the_geom)

         UNION

         SELECT country.iso_3, ST_Makevalid(ST_Intersection(country.land_geom, polygon.wkb_geometry)) FROM standard_polygons polygon
           INNER JOIN countries country ON ST_Intersects(country.land_geom, polygon.wkb_geometry)
           WHERE polygon.iso3 LIKE '%,%'
            AND country.iso_3 = 'GBR'
            AND polygon.marine = '1'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')
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
         SELECT  iso3, ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.00000001)) the_geom FROM standard_polygons polygon
           WHERE polygon.iso3 = 'GBR'
            AND ST_IsValid(polygon.wkb_geometry)
            AND polygon.marine = '0'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')

         UNION

         SELECT iso3, the_geom FROM (
           SELECT iso3, ST_Buffer(wkb_geometry::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
           FROM standard_points point
           WHERE point.iso3 = 'GBR'
             AND point.marine = '0'
             AND point.status NOT IN ('Proposed', 'Not Reported')
         ) AS c
         WHERE ST_IsValid(the_geom)

         UNION

         SELECT country.iso_3, ST_Makevalid(ST_Intersection(country.land_geom, polygon.wkb_geometry)) FROM standard_polygons polygon
           INNER JOIN countries country ON ST_Intersects(country.land_geom, polygon.wkb_geometry)
           WHERE polygon.iso3 LIKE '%,%'
            AND country.iso_3 = 'GBR'
            AND polygon.marine = '0'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')
        ) b
      ) a
      WHERE iso_3 = 'GBR'
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(marine_query)
    ActiveRecord::Base.connection.expects(:execute).with(land_query)

    Geospatial::CountryGeometryPopulator.populate_dissolved_geometries country
  end
end
