require 'test_helper'

class TestGeospatialGeometry < ActiveSupport::TestCase
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
end