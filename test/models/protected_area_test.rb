require 'test_helper'
require 'rgeo'

class ProtectedAreaTest < ActiveSupport::TestCase
  test ".create creates a postgis geometry from a WKT geometry" do
    protected_area = ProtectedArea.create(the_geom: "POINT (1.0 1.0)")

    assert_kind_of RGeo::Geos::CAPIPointImpl, protected_area.the_geom
    assert_equal   "POINT (1.0 1.0)", protected_area.the_geom.to_s
  end

  test '.bounds returns the bounding box for the PA geometry' do
    protected_area = FactoryGirl.create(:protected_area, the_geom: 'POLYGON ((-1 0, 0 1, 1 2, 1 0, -1 0))')

    assert_equal [[0, -1], [2, 1]], protected_area.bounds
  end
end
