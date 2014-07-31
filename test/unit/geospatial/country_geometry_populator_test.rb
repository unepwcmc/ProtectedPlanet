require 'test_helper'

class CountryGeometryPopulatorTest < ActiveSupport::TestCase

  test '#repair_geometries repairs not valid geometries from standard_polygons' do
    repair_query = """UPDATE standard_polygons
                      SET wkb_geometry = ST_Makevalid(ST_Multi(ST_Buffer(wkb_geometry,0.0)))
                      WHERE NOT ST_IsValid(wkb_geometry)""".squish

    ActiveRecord::Base.connection.expects(:execute).with(repair_query)
    Geospatial::CountryGeometryPopulator.repair_geometries
  end


  test '#populate_dissolved_geometries, given a country, dissolves the marine and terrestrial
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
            AND polygon.desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')

         UNION

         SELECT iso3, the_geom FROM (
           SELECT iso3, ST_Buffer(wkb_geometry::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
           FROM standard_points point
           WHERE point.iso3 = 'FAK'
             AND point.marine = '1'
             AND point.status NOT IN ('Proposed', 'Not Reported')
             AND point.desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
         ) AS c
         WHERE ST_IsValid(the_geom)

         UNION

         SELECT country.iso_3, ST_Makevalid(ST_Intersection(ST_Buffer(country.land_geom,0.0), polygon.wkb_geometry)) FROM standard_polygons polygon
           INNER JOIN countries country ON ST_Intersects(ST_Buffer(country.land_geom,0.0), polygon.wkb_geometry)
           WHERE polygon.iso3 LIKE '%,%'
            AND country.iso_3 = 'FAK'
            AND polygon.marine = '1'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')
            AND polygon.desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
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
            AND polygon.desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')

         UNION

         SELECT iso3, the_geom FROM (
           SELECT iso3, ST_Buffer(wkb_geometry::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
           FROM standard_points point
           WHERE point.iso3 = 'FAK'
             AND point.marine = '0'
             AND point.status NOT IN ('Proposed', 'Not Reported')
             AND point.desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
         ) AS c
         WHERE ST_IsValid(the_geom)

         UNION

         SELECT country.iso_3, ST_Makevalid(ST_Intersection(ST_Buffer(country.land_geom,0.0), polygon.wkb_geometry)) FROM standard_polygons polygon
           INNER JOIN countries country ON ST_Intersects(ST_Buffer(country.land_geom,0.0), polygon.wkb_geometry)
           WHERE polygon.iso3 LIKE '%,%'
            AND country.iso_3 = 'FAK'
            AND polygon.marine = '0'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')
            AND polygon.desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
        ) b
      ) a
      WHERE iso_3 = 'FAK'
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(marine_query)
    ActiveRecord::Base.connection.expects(:execute).with(land_query)

    Geospatial::CountryGeometryPopulator.populate_dissolved_geometries country
  end

  test '#populate_dissolved_geometries, given a country defined as "complex", simplifies the
   marine geometry' do
    country = FactoryGirl.build(:country, iso_3: 'GBR')

    marine_query = """
      UPDATE countries
      SET marine_pas_geom = a.the_geom
      FROM (
       SELECT ST_UNION(the_geom) as the_geom
       FROM (
         SELECT  iso3, ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.0)) the_geom FROM standard_polygons polygon
           WHERE polygon.iso3 = 'GBR'
            AND ST_IsValid(polygon.wkb_geometry)
            AND polygon.marine = '1'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')
            AND polygon.desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')

         UNION

         SELECT iso3, the_geom FROM (
           SELECT iso3, ST_Buffer(wkb_geometry::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
           FROM standard_points point
           WHERE point.iso3 = 'GBR'
             AND point.marine = '1'
             AND point.status NOT IN ('Proposed', 'Not Reported')
             AND point.desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
         ) AS c
         WHERE ST_IsValid(the_geom)

         UNION

         SELECT country.iso_3, ST_Makevalid(ST_Intersection(ST_Buffer(country.land_geom,0.0), polygon.wkb_geometry)) FROM standard_polygons polygon
           INNER JOIN countries country ON ST_Intersects(ST_Buffer(country.land_geom,0.0), polygon.wkb_geometry)
           WHERE polygon.iso3 LIKE '%,%'
            AND country.iso_3 = 'GBR'
            AND polygon.marine = '1'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')
            AND polygon.desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
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
         SELECT  iso3, ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.0)) the_geom FROM standard_polygons polygon
           WHERE polygon.iso3 = 'GBR'
            AND ST_IsValid(polygon.wkb_geometry)
            AND polygon.marine = '0'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')
            AND polygon.desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')

         UNION

         SELECT iso3, the_geom FROM (
           SELECT iso3, ST_Buffer(wkb_geometry::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
           FROM standard_points point
           WHERE point.iso3 = 'GBR'
             AND point.marine = '0'
             AND point.status NOT IN ('Proposed', 'Not Reported')
             AND point.desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
         ) AS c
         WHERE ST_IsValid(the_geom)

         UNION

         SELECT country.iso_3, ST_Makevalid(ST_Intersection(ST_Buffer(country.land_geom,0.0), polygon.wkb_geometry)) FROM standard_polygons polygon
           INNER JOIN countries country ON ST_Intersects(ST_Buffer(country.land_geom,0.0), polygon.wkb_geometry)
           WHERE polygon.iso3 LIKE '%,%'
            AND country.iso_3 = 'GBR'
            AND polygon.marine = '0'
            AND polygon.status NOT IN ('Proposed', 'Not Reported')
            AND polygon.desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
        ) b
      ) a
      WHERE iso_3 = 'GBR'
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(marine_query)
    ActiveRecord::Base.connection.expects(:execute).with(land_query)

    Geospatial::CountryGeometryPopulator.populate_dissolved_geometries country
  end

  test '#populate_marine_geometries, given a country, sets the EEZ and
   Territorial Water geometries for that country' do
    country = FactoryGirl.build(:country, iso_3: 'FAK')

    eez_query = """
      UPDATE countries SET marine_eez_pas_geom = (
        SELECT ST_Intersection(marine_pas_geom, ST_Buffer(eez_geom,0.0))
        FROM countries
        WHERE iso_3 = 'FAK' AND ST_Intersects(marine_pas_geom, ST_Buffer(eez_geom,0.0)) LIMIT 1
      ) WHERE iso_3 = 'FAK'
    """.squish

    territorial_query = """
      UPDATE countries SET marine_ts_pas_geom = (
        SELECT
        ST_Intersection(marine_pas_geom, ST_Buffer(ts_geom,0.0))
        FROM countries
        WHERE iso_3 = 'FAK' AND ST_Intersects(marine_pas_geom, ST_Buffer(ts_geom,0.0)) LIMIT 1
      ) WHERE iso_3 = 'FAK'
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(eez_query)
    ActiveRecord::Base.connection.expects(:execute).with(territorial_query)

    Geospatial::CountryGeometryPopulator.populate_marine_geometries country
  end
end
