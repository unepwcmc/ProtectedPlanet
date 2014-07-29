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

  test '#mappings returns the Elastic Search index mappings' do
    expected_mapping = {
      protected_area: {
        dynamic: "false",
        properties: {
          type: { type: "string" },
          name: { type: "string" },
          original_name: { type: "string" },
          marine: { type: "boolean" },
          sub_location: {
            type: "nested",
            properties: {
              name: { type: "string", index: "not_analyzed" }
            }
          },
          countries: {
            type: 'nested',
            properties: {
              id: { type: 'integer' },
              name: { type: 'string', index: 'not_analyzed' },
              region: {
                type: 'nested',
                properties: {
                  id: { type: 'integer' },
                  name: { type: 'string', index: 'not_analyzed' }
                }
              }
            }
          },
          iucn_category: {
            type: 'nested',
            properties: {
              id: { type: 'integer' },
              name: { type: 'string', index: 'not_analyzed' }
            }
          },
          designation: {
            type: 'nested',
            properties: {
              id: { type: 'integer' },
              name: { type: 'string', index: 'not_analyzed'  }
            }
          },
        }
      }
    }
    actual_mapping = ProtectedArea.mappings.to_hash

    assert_equal expected_mapping, actual_mapping
  end
end
