require 'test_helper'
require 'rgeo'

class ProtectedAreaTest < ActiveSupport::TestCase
  test ".create creates a postgis geometry from a WKT geometry" do
    protected_area = ProtectedArea.create(the_geom: "POINT (1.0 1.0)")

    assert_kind_of RGeo::Geos::CAPIPointImpl, protected_area.the_geom
    assert_equal   "POINT (1.0 1.0)", protected_area.the_geom.to_s
  end

  test ".save creates a slug attribute consisting of parameterized name
   and designation" do
    designation = FactoryGirl.create(:designation, name: 'Protected Area')
    protected_area = ProtectedArea.create(name: 'Finn and Jake Land', designation: designation)

    assert_equal 'finn-and-jake-land-protected-area', protected_area.slug
  end

  test ".save creates a slug attribute consisting of parameterized name
   only, if designation is not set" do
    protected_area = ProtectedArea.create(name: 'Finn and Jake Land')

    assert_equal 'finn-and-jake-land', protected_area.slug
  end

  test ".bounds returns the bounding box for the PA geometry" do
    protected_area = FactoryGirl.create(:protected_area, the_geom: 'POLYGON ((-1 0, 0 1, 1 2, 1 0, -1 0))')

    assert_equal [[0, -1], [2, 1]], protected_area.bounds
  end
end
