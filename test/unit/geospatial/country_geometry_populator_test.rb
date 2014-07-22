require 'test_helper'

class CountryGeometryPopulatorTest < ActiveSupport::TestCase
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
         SELECT  iso3, ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.00000001)) the_geom FROM standard_polygons polygon
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
         SELECT  iso3, ST_Makevalid(ST_Buffer(ST_Simplify(wkb_geometry,0.005),0.00000001)) the_geom FROM standard_polygons polygon
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
        SELECT CASE
            WHEN ST_Within(marine_pas_geom, eez_geom)
            THEN marine_pas_geom
            ELSE ST_Intersection(marine_pas_geom, eez_geom)
          END
        FROM countries
        WHERE iso_3 = 'FAK' LIMIT 1
      ) WHERE iso_3 = 'FAK'
    """.squish

    territorial_query = """
      UPDATE countries SET marine_ts_pas_geom = (
        SELECT CASE
            WHEN ST_Within(marine_pas_geom, ts_geom)
            THEN marine_pas_geom
            ELSE ST_Intersection(marine_pas_geom, ts_geom)
          END
        FROM countries
        WHERE iso_3 = 'FAK' LIMIT 1
      ) WHERE iso_3 = 'FAK'
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(eez_query)
    ActiveRecord::Base.connection.expects(:execute).with(territorial_query)

    Geospatial::CountryGeometryPopulator.populate_marine_geometries country
  end

  test '#populate_marine_geometries, given a country that has topology
   problems, sets the EEZ and Territorial Water geometries by first
   making them valid' do
    country = FactoryGirl.build(:country, iso_3: 'HRV')

    eez_query = """
      UPDATE countries SET marine_eez_pas_geom = (
        SELECT ST_MakeValid(
          ST_Intersection(
            ST_MakeValid(ST_Buffer(ST_Simplify(marine_pas_geom,0.005),0.00000001)),
            ST_MakeValid(ST_Buffer(ST_Simplify(eez_geom,0.005),0.00000001))
          )
        )
        FROM countries
        WHERE iso_3 = 'HRV' LIMIT 1
      ) WHERE iso_3 = 'HRV'
    """.squish

    territorial_query = """
      UPDATE countries SET marine_ts_pas_geom = (
        SELECT ST_MakeValid(
          ST_Intersection(
            ST_MakeValid(ST_Buffer(ST_Simplify(marine_pas_geom,0.005),0.00000001)),
            ST_MakeValid(ST_Buffer(ST_Simplify(ts_geom,0.005),0.00000001))
          )
        )
        FROM countries
        WHERE iso_3 = 'HRV' LIMIT 1
      ) WHERE iso_3 = 'HRV'
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(eez_query)
    ActiveRecord::Base.connection.expects(:execute).with(territorial_query)

    Geospatial::CountryGeometryPopulator.populate_marine_geometries country
  end

  test '#populate_marine_geometries, given a country with topology
   problems, it buffers and makes valid the geometries' do
    country = FactoryGirl.build(:country, iso_3: 'RUS')

    eez_query = """
      UPDATE countries SET marine_eez_pas_geom = (
        SELECT CASE
            WHEN ST_Within(marine_pas_geom, eez_geom)
            THEN marine_pas_geom
            ELSE ST_Intersection(ST_MakeValid(ST_Buffer(ST_Simplify(marine_pas_geom,0.005),0.00000001)),
              ST_MakeValid(ST_Buffer(ST_Simplify(eez_geom,0.005),0.00000001)))
          END
        FROM countries
        WHERE iso_3 = 'RUS' LIMIT 1
      ) WHERE iso_3 = 'RUS'
    """.squish

    territorial_query = """
      UPDATE countries SET marine_ts_pas_geom = (
        SELECT CASE
            WHEN ST_Within(marine_pas_geom, ts_geom)
            THEN marine_pas_geom
            ELSE ST_Intersection(ST_MakeValid(ST_Buffer(ST_Simplify(marine_pas_geom,0.005),0.00000001)),
              ST_MakeValid(ST_Buffer(ST_Simplify(ts_geom,0.005),0.00000001)))
          END
        FROM countries
        WHERE iso_3 = 'RUS' LIMIT 1
      ) WHERE iso_3 = 'RUS'
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(eez_query)
    ActiveRecord::Base.connection.expects(:execute).with(territorial_query)

    Geospatial::CountryGeometryPopulator.populate_marine_geometries country
  end

end
