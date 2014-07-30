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
    protected_area = FactoryGirl.create(:protected_area, the_geom: 'POLYGON ((-1.5 0, 0 1, 1 2, 1 0, -1.5 0))')

    assert_equal [[0, -1.5], [2, 1]], protected_area.bounds
  end

  test ".bounds only calls the database once" do
    protected_area = FactoryGirl.create(:protected_area, the_geom: 'POLYGON ((-1.5 0, 0 1, 1 2, 1 0, -1.5 0))')

    ActiveRecord::Base.connection.expects(:execute).returns([{}]).once

    protected_area.bounds
  end

  test '.without_geometry does not select the_geom' do
    geometry_wkt = "POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))"
    protected_area = FactoryGirl.create(:protected_area, the_geom: geometry_wkt)

    selected_protected_area = ProtectedArea.without_geometry.find(protected_area.id)
    refute selected_protected_area.has_attribute?(:the_geom)
  end

  test '.as_indexed_json returns the PA as JSON with nested attributes' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, name: 'Manboneland', region: region)
    sub_location = FactoryGirl.create(:sub_location, english_name: 'Manboneland City')

    iucn_category = FactoryGirl.create(:iucn_category, id: 456, name: 'IA')
    designation = FactoryGirl.create(:designation, id: 654, name: 'National')

    pa = FactoryGirl.create(:protected_area,
      name: 'Manbone', countries: [country], sub_locations: [sub_location],
      original_name: 'Manboné', iucn_category: iucn_category,
      designation: designation, marine: true
    )

    expected_json = {
      "type" => 'protected_area',
      "name" => 'Manbone',
      "original_name" => "Manboné",
      "marine" => true,
      "sub_locations" => [
        {
          "english_name" => "Manboneland City"
        }
      ],
      "countries" => [
        {
          "id" => 123,
          "name" => "Manboneland",
          "region" => {
            "id" => 987,
            "name" => "North Manmerica"
          }
        }
      ],
      "iucn_category" => {
        "id" => 456,
        "name" => "IA"
      },
      "designation" => {
        "id" => 654,
        "name" => "National"
      }
    }

    assert_equal expected_json, pa.as_indexed_json
  end
end
