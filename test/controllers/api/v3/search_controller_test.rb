require 'test_helper'

class Api::V3::SearchControllerTest < ActionController::TestCase
  test 'GET :by_point, given coordinates, returns an array of
   PAs closest to that point' do
    query = """
      SELECT p.id, p.site_id, p.name, p.the_geom_latitude, p.the_geom_longitude
      FROM protected_areas p
      WHERE ST_DWithin(p.the_geom, ST_GeomFromText('POINT(2.0 1.0)',4326), 0.0000001)
      LIMIT 1;
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(query)

    get :by_point, params: {lat: 1, lon: 2, distance: 1}
    assert_response :success
  end
end
