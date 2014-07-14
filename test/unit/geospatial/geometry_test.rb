require 'test_helper'

class TestGeospatialGeometry < ActiveSupport::TestCase


  test '.drops indexes' do
    complex_countries_land = ['BUM', 'COM']
    complex_countries_marine = ['LEO']
    ActiveRecord::Base.connection.
      expects(:execute).
      with("""DROP INDEX IF EXISTS land_pas_geom_gindx;
              DROP INDEX IF EXISTS marine_pas_geom_gindx;
           """.squish).
      returns(true)

    geometry_operator = Geospatial::Geometry.new(complex_countries_land,complex_countries_marine)
    response = geometry_operator.drop_indexes

    assert response, "Expected update_table to return true on success"
 end

  test '.merges geometries for countries with simple land geometries' do
     FactoryGirl.create(:country, iso_3: 'BAM')
     complex_countries_land = ['BUM', 'COM']
     complex_countries_marine = ['LEO']




     ActiveRecord::Base.connection.
     expects(:execute).
     with("""UPDATE countries
             SET land_pas_geom = a.the_geom
             FROM (SELECT ST_UNION(wkb_geometry) as the_geom
             FROM standard_polygons
             WHERE iso3 = 'BAM' AND st_isvalid(wkb_geometry) AND marine = '0') a
             WHERE iso_3 = 'BAM'""".squish).
     returns true

     ActiveRecord::Base.connection.
     expects(:execute).
     with("""UPDATE countries
             SET marine_pas_geom = a.the_geom
             FROM (SELECT ST_UNION(wkb_geometry) as the_geom
             FROM standard_polygons
             WHERE iso3 = 'BAM' AND st_isvalid(wkb_geometry) AND marine = '1') a
             WHERE iso_3 = 'BAM'""".squish).
     returns true


      geometry_operator = Geospatial::Geometry.new(complex_countries_land,complex_countries_marine)
      response = geometry_operator.dissolve_countries

      assert response, 'Expects query'
  end

  test '.creates indexes' do
    complex_countries_land = ['BUM', 'COM']
    complex_countries_marine = ['LEO']
    ActiveRecord::Base.connection.
      expects(:execute).
      with("""CREATE INDEX land_pas_geom_gindx ON countries USING GIST (land_pas_geom);
              CREATE INDEX marine_pas_geom_gindx ON countries USING GIST (marine_pas_geom);
              """.squish).
      returns(true)

    geometry_operator = Geospatial::Geometry.new(complex_countries_land,complex_countries_marine)
    response = geometry_operator.create_indexes
    assert response, "Expected update_table to return true on success"

  end
end