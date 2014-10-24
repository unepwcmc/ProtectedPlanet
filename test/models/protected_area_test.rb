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
      designation: designation, marine: true, wdpa_id: 555999
    )

    expected_json = {
      "id" => pa.id,
      "wdpa_id" => 555999,
      "name" => 'Manbone',
      "original_name" => "Manboné",
      "marine" => true,
      "sub_locations" => [
        {
          "english_name" => "Manboneland City"
        }
      ],
      "countries_for_index" => [
        {
          "id" => 123,
          "name" => "Manboneland",
          "region_for_index" => {
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

  test '#with_valid_iucn_categories returns PAs with valid IUCN
   categories' do
    iucn_category_1 = FactoryGirl.create(:iucn_category, name: 'Ib')
    iucn_category_2 = FactoryGirl.create(:iucn_category, name: 'V')
    no_iucn_category = FactoryGirl.create(:iucn_category, name: 'Cristiano Ronaldo')

    FactoryGirl.create(:protected_area, iucn_category: iucn_category_1)
    FactoryGirl.create(:protected_area, iucn_category: iucn_category_2)
    FactoryGirl.create(:protected_area, iucn_category: no_iucn_category)
    assert_equal 2, ProtectedArea.with_valid_iucn_categories.count
  end

  test '.as_api_feeder returns the PA as JSON with requested attributes' do

  time = Time.local(2008, 9, 1, 10, 5, 0)

  region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
  country = FactoryGirl.create(:country, id: 123, iso_3: 'MBN', name: 'Manboneland', region: region)
  sub_location = FactoryGirl.create(:sub_location, english_name: 'Manboneland City')

  jurisdiction = FactoryGirl.create(:jurisdiction, id: 2, name: 'International')
  iucn_category = FactoryGirl.create(:iucn_category, id: 456, name: 'IA')
  designation = FactoryGirl.create(:designation, id: 654, name: 'National', jurisdiction: jurisdiction)
  governance = FactoryGirl.create(:governance, id: 111, name: 'Bone Man')
  legal_status = FactoryGirl.create(:legal_status, id: 987, name: 'Proposed')

  pa = FactoryGirl.create(:protected_area,
    name: 'Manbone', countries: [country], sub_locations: [sub_location],
    original_name: 'Manboné', iucn_category: iucn_category,
    designation: designation, governance: governance,
    legal_status: legal_status, legal_status_updated_at: time, marine: true, wdpa_id: 555999,
    reported_area: 10.2)

    expected_json = {
      "wdpa_id" => 555999,
      "name" => 'Manbone',
      "original_name" => "Manboné",
      "marine" => true,
      "legal_status_updated_at" => time,
      "sub_locations" => [
        {
          "english_name" => "Manboneland City"
        }
      ],
      "countries" => [
        {
          "name" => "Manboneland",
          "iso_3" => "MBN",
          "region" => {
            "name" => "North Manmerica"
          }
        }
      ],
      "iucn_category" => {
        "name" => "IA"
      },
      "designation" => {
        "name" => "National",
        "jurisdiction" => {
          "name" => "International"
        }
      },
      "legal_status" => {
        "name" => "Proposed"
      }
    }

    assert_equal expected_json, pa.as_api_feeder
  end
end
